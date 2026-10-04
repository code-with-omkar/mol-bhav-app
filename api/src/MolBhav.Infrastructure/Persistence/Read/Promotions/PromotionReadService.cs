using Dapper;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Promotions;
using MolBhav.Infrastructure.Persistence.Configurations.Identity;
using MolBhav.Infrastructure.Persistence.Configurations.Market;
using MolBhav.Infrastructure.Persistence.Configurations.Promotions;

namespace MolBhav.Infrastructure.Persistence.Read.Promotions;

/// <summary>
/// Serving and admin reporting for sponsored campaigns. Serving is one statement per slot render: the
/// <c>ix_campaigns_active_placement_ends_at_utc</c> partial index narrows to running campaigns of the placement,
/// the targeting EXISTS probes <c>(campaign_id, category_code)</c>, and today's counts come from the stats PK.
/// </summary>
internal sealed class PromotionReadService(IDbConnectionFactory connectionFactory) : IPromotionReadService
{
    private const string Advertisers = Schemas.Promotions + "." + AdvertiserConfiguration.TableName;
    private const string Campaigns = Schemas.Promotions + "." + CampaignConfiguration.TableName;
    private const string Targets = Schemas.Promotions + "." + CampaignTargetConfiguration.TableName;
    private const string Stats = Schemas.Promotions + "." + CampaignDailyStatConfiguration.TableName;
    private const string States = Schemas.Market + "." + StateConfiguration.TableName;
    private const string Users = UserConfiguration.QualifiedTableName;
    private const string UserCategories = UserConfiguration.QualifiedCategoriesTableName;

    // The profile stores the state picker's code (older rows: the state name) — resolved like the profile screen does.
    // A user with no resolvable state still matches campaigns that target every state.
    private const string ServeSql = $"""
        WITH me AS (
            SELECT u.id AS user_id, s.id AS state_id
            FROM {Users} u
            LEFT JOIN LATERAL (
                SELECT st.id
                FROM {States} st
                WHERE upper(st.code) = upper(u.state) OR lower(st.name) = lower(u.state)
                ORDER BY (upper(st.code) = upper(u.state)) DESC
                LIMIT 1
            ) s ON TRUE
            WHERE u.id = @UserId AND u.is_deleted = false
        )
        SELECT c.id AS campaign_id, a.name AS advertiser_name, c.title, c.body, c.cta_label, c.cta_url, c.image_url
        FROM me
        JOIN {Campaigns} c
          ON c.status = 'Active'
         AND c.placement = @Placement
         AND c.starts_at_utc <= @NowUtc
         AND c.ends_at_utc > @NowUtc
        JOIN {Advertisers} a ON a.id = c.advertiser_id
        LEFT JOIN {Stats} ds ON ds.campaign_id = c.id AND ds.day = @Day
        WHERE (c.daily_impression_cap IS NULL OR coalesce(ds.impressions, 0) < c.daily_impression_cap)
          AND EXISTS (
              SELECT 1
              FROM {Targets} t
              JOIN {UserCategories} uc ON uc.user_id = me.user_id AND uc.category_code = t.category_code
              WHERE t.campaign_id = c.id
                AND (t.state_id IS NULL OR t.state_id = me.state_id))
        ORDER BY c.priority DESC, coalesce(ds.impressions, 0), c.id
        LIMIT 1;
        """;

    private const string AdvertisersSql = $"""
        SELECT a.id, a.name, a.contact_name, a.contact_phone, a.gstin,
               (SELECT count(*)::int FROM {Campaigns} c WHERE c.advertiser_id = a.id AND c.status = 'Active') AS active_campaigns
        FROM {Advertisers} a
        ORDER BY a.name, a.id;
        """;

    private const string AdminWhere = """
        WHERE (@Status::text IS NULL OR c.status = @Status::text)
          AND (@AdvertiserId::uuid IS NULL OR c.advertiser_id = @AdvertiserId::uuid)
        """;

    private static readonly string CampaignsSql = $"""
        SELECT count(*) FROM {Campaigns} c
        {AdminWhere};

        SELECT c.id, c.advertiser_id, a.name AS advertiser_name, c.name, c.placement, c.status,
               c.starts_at_utc, c.ends_at_utc, c.priority, c.daily_impression_cap,
               c.title, c.body, c.cta_label, c.cta_url, c.image_url,
               coalesce(td.impressions, 0)::bigint AS impressions_today,
               coalesce(td.clicks, 0)::bigint      AS clicks_today,
               coalesce(tot.impressions, 0)::bigint AS impressions_total,
               coalesce(tot.clicks, 0)::bigint      AS clicks_total
        FROM {Campaigns} c
        JOIN {Advertisers} a ON a.id = c.advertiser_id
        LEFT JOIN {Stats} td ON td.campaign_id = c.id AND td.day = @Day
        LEFT JOIN LATERAL (
            SELECT sum(s.impressions) AS impressions, sum(s.clicks) AS clicks
            FROM {Stats} s
            WHERE s.campaign_id = c.id
        ) tot ON TRUE
        {AdminWhere}
        ORDER BY c.created_at_utc DESC, c.id
        LIMIT @Limit OFFSET @Offset;
        """;

    private const string TargetsSql = $"""
        SELECT t.campaign_id, t.category_code, t.state_id
        FROM {Targets} t
        WHERE t.campaign_id = ANY(@Ids)
        ORDER BY t.category_code, t.state_id NULLS FIRST;
        """;

    private const string DailyStatsSql = $"""
        SELECT s.day, s.impressions::bigint AS impressions, s.clicks::bigint AS clicks
        FROM {Stats} s
        WHERE s.campaign_id = @CampaignId AND s.day BETWEEN @From AND @To
        ORDER BY s.day;
        """;

    public async Task<PromotionResponse?> FindForUserAsync(
        Guid userId,
        PromotionPlacement placement,
        DateTimeOffset nowUtc,
        DateOnly istDay,
        CancellationToken cancellationToken = default)
    {
        var args = new DynamicParameters();
        args.Add("UserId", userId);
        args.Add("Placement", placement.ToString());
        args.Add("NowUtc", nowUtc.ToUniversalTime());
        args.Add("Day", istDay);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var row = await connection.QuerySingleOrDefaultAsync<ServeRow>(Command(ServeSql, args, cancellationToken));

        return row is null
            ? null
            : new PromotionResponse(row.CampaignId, row.AdvertiserName, row.Title, row.Body, row.CtaLabel, row.CtaUrl, row.ImageUrl);
    }

    public async Task<IReadOnlyList<AdvertiserResponse>> GetAdvertisersAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<AdvertiserRow>(Command(AdvertisersSql, null, cancellationToken));

        return rows
            .Select(r => new AdvertiserResponse(r.Id, r.Name, r.ContactName, r.ContactPhone, r.Gstin, r.ActiveCampaigns))
            .ToArray();
    }

    public async Task<PagedResult<AdminCampaignResponse>> GetCampaignsAsync(
        AdminCampaignFilter filter,
        DateOnly istDay,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("Status", filter.Status?.ToString());
        args.Add("AdvertiserId", filter.AdvertiserId);
        args.Add("Day", istDay);
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);

        long totalCount;
        List<CampaignRow> rows;
        await using (var grid = await connection.QueryMultipleAsync(Command(CampaignsSql, args, cancellationToken)))
        {
            totalCount = await grid.ReadSingleAsync<long>();
            rows = (await grid.ReadAsync<CampaignRow>()).ToList();
        }

        ILookup<Guid, CampaignTargetResponse> targets = Array.Empty<TargetRow>()
            .ToLookup(t => t.CampaignId, t => new CampaignTargetResponse(t.CategoryCode, t.StateId));
        if (rows.Count > 0)
        {
            var ids = rows.Select(r => r.Id).ToArray();
            var targetRows = await connection.QueryAsync<TargetRow>(Command(TargetsSql, new { Ids = ids }, cancellationToken));
            targets = targetRows.ToLookup(t => t.CampaignId, t => new CampaignTargetResponse(t.CategoryCode, t.StateId));
        }

        var items = rows.Select(r => new AdminCampaignResponse(
                r.Id,
                r.AdvertiserId,
                r.AdvertiserName,
                r.Name,
                Enum.Parse<PromotionPlacement>(r.Placement),
                Enum.Parse<CampaignStatus>(r.Status),
                r.StartsAtUtc,
                r.EndsAtUtc,
                r.Priority,
                r.DailyImpressionCap,
                r.Title,
                r.Body,
                r.CtaLabel,
                r.CtaUrl,
                r.ImageUrl,
                targets[r.Id].ToArray(),
                r.ImpressionsToday,
                r.ClicksToday,
                r.ImpressionsTotal,
                r.ClicksTotal))
            .ToArray();

        return new PagedResult<AdminCampaignResponse>(items, filter.Page.Page, filter.Page.PageSize, totalCount);
    }

    public async Task<IReadOnlyList<CampaignDailyStatResponse>> GetDailyStatsAsync(
        Guid campaignId,
        DateOnly from,
        DateOnly to,
        CancellationToken cancellationToken = default)
    {
        var args = new DynamicParameters();
        args.Add("CampaignId", campaignId);
        args.Add("From", from);
        args.Add("To", to);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<StatRow>(Command(DailyStatsSql, args, cancellationToken));

        return rows.Select(r => new CampaignDailyStatResponse(r.Day, r.Impressions, r.Clicks)).ToArray();
    }

    private static CommandDefinition Command(string sql, object? args, CancellationToken cancellationToken) =>
        new(sql, args, cancellationToken: cancellationToken);

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class ServeRow
    {
        public Guid CampaignId { get; init; }

        public string AdvertiserName { get; init; } = string.Empty;

        public string Title { get; init; } = string.Empty;

        public string Body { get; init; } = string.Empty;

        public string CtaLabel { get; init; } = string.Empty;

        public string CtaUrl { get; init; } = string.Empty;

        public string? ImageUrl { get; init; }
    }

    private sealed class AdvertiserRow
    {
        public Guid Id { get; init; }

        public string Name { get; init; } = string.Empty;

        public string? ContactName { get; init; }

        public string? ContactPhone { get; init; }

        public string? Gstin { get; init; }

        public int ActiveCampaigns { get; init; }
    }

    private sealed class CampaignRow
    {
        public Guid Id { get; init; }

        public Guid AdvertiserId { get; init; }

        public string AdvertiserName { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public string Placement { get; init; } = string.Empty;

        public string Status { get; init; } = string.Empty;

        public DateTimeOffset StartsAtUtc { get; init; }

        public DateTimeOffset EndsAtUtc { get; init; }

        public int Priority { get; init; }

        public int? DailyImpressionCap { get; init; }

        public string Title { get; init; } = string.Empty;

        public string Body { get; init; } = string.Empty;

        public string CtaLabel { get; init; } = string.Empty;

        public string CtaUrl { get; init; } = string.Empty;

        public string? ImageUrl { get; init; }

        public long ImpressionsToday { get; init; }

        public long ClicksToday { get; init; }

        public long ImpressionsTotal { get; init; }

        public long ClicksTotal { get; init; }
    }

    private sealed class TargetRow
    {
        public Guid CampaignId { get; init; }

        public string CategoryCode { get; init; } = string.Empty;

        public Guid? StateId { get; init; }
    }

    private sealed class StatRow
    {
        public DateOnly Day { get; init; }

        public long Impressions { get; init; }

        public long Clicks { get; init; }
    }
#pragma warning restore CA1812
}
