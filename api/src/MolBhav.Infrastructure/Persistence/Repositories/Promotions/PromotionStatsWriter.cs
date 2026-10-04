using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Domain.Promotions;
using MolBhav.Infrastructure.Persistence.Configurations.Identity;
using MolBhav.Infrastructure.Persistence.Configurations.Market;
using MolBhav.Infrastructure.Persistence.Configurations.Promotions;
using Npgsql;

namespace MolBhav.Infrastructure.Persistence.Repositories.Promotions;

/// <summary>
/// Credits client-reported delivery in one statement on the EF connection, so it joins the command's unit-of-work
/// transaction: if the execution strategy retries the command, the rolled-back attempt left nothing behind.
/// <list type="number">
/// <item><c>eligible</c> keeps campaigns servable now that target this user — the same rule serving uses.</item>
/// <item>The user's new ledger totals are planned from today's row with the daily caps applied (clicks never above
/// impressions) and upserted monotonically (<c>greatest</c>).</item>
/// <item>Only the increase that ledger actually granted is added to the campaign's daily totals.</item>
/// </list>
/// Both upserts lock rows in campaign-id order, so concurrent batches can't deadlock. Two simultaneous batches from
/// the same user can each see the ledger before the other's update and over-credit by at most one request's cap —
/// bounded, and already throttled by the per-user rate limit.
/// </summary>
internal sealed class PromotionStatsWriter(MolBhavDbContext dbContext) : IPromotionStatsWriter
{
    private const string Campaigns = Schemas.Promotions + "." + CampaignConfiguration.TableName;
    private const string Targets = Schemas.Promotions + "." + CampaignTargetConfiguration.TableName;
    private const string Stats = Schemas.Promotions + "." + CampaignDailyStatConfiguration.TableName;
    private const string Ledger = Schemas.Promotions + "." + CampaignUserDailyCountConfiguration.TableName;
    private const string States = Schemas.Market + "." + StateConfiguration.TableName;
    private const string Users = UserConfiguration.QualifiedTableName;
    private const string UserCategories = UserConfiguration.QualifiedCategoriesTableName;

    private const string Sql = $"""
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
        ),
        input AS (
            SELECT d.campaign_id, d.impressions, d.clicks
            FROM unnest(@CampaignIds, @Impressions, @Clicks) AS d(campaign_id, impressions, clicks)
        ),
        eligible AS (
            SELECT i.campaign_id, i.impressions, i.clicks
            FROM input i
            CROSS JOIN me
            JOIN {Campaigns} c
              ON c.id = i.campaign_id
             AND c.status = 'Active'
             AND c.starts_at_utc <= @NowUtc
             AND c.ends_at_utc > @NowUtc
            WHERE EXISTS (
                SELECT 1
                FROM {Targets} t
                JOIN {UserCategories} uc ON uc.user_id = me.user_id AND uc.category_code = t.category_code
                WHERE t.campaign_id = c.id
                  AND (t.state_id IS NULL OR t.state_id = me.state_id))
        ),
        prior AS (
            SELECT l.campaign_id, l.impressions, l.clicks
            FROM {Ledger} l
            WHERE l.user_id = @UserId AND l.day = @Day AND l.campaign_id IN (SELECT e.campaign_id FROM eligible e)
        ),
        planned AS (
            SELECT x.campaign_id, x.impressions, least(x.clicks, @MaxClicks, x.impressions) AS clicks
            FROM (
                SELECT e.campaign_id,
                       least(coalesce(p.impressions, 0) + e.impressions, @MaxImpressions) AS impressions,
                       coalesce(p.clicks, 0) + e.clicks                                    AS clicks
                FROM eligible e
                LEFT JOIN prior p ON p.campaign_id = e.campaign_id
            ) x
        ),
        credited AS (
            INSERT INTO {Ledger} AS l (campaign_id, user_id, day, impressions, clicks)
            SELECT pl.campaign_id, @UserId, @Day, pl.impressions, pl.clicks
            FROM planned pl
            ORDER BY pl.campaign_id
            ON CONFLICT (campaign_id, user_id, day) DO UPDATE
            SET impressions = greatest(l.impressions, EXCLUDED.impressions),
                clicks      = greatest(l.clicks, EXCLUDED.clicks)
            RETURNING l.campaign_id, l.impressions, l.clicks
        ),
        delta AS (
            SELECT cr.campaign_id,
                   cr.impressions - coalesce(p.impressions, 0) AS impressions,
                   cr.clicks - coalesce(p.clicks, 0)           AS clicks
            FROM credited cr
            LEFT JOIN prior p ON p.campaign_id = cr.campaign_id
        )
        INSERT INTO {Stats} AS s (campaign_id, day, impressions, clicks)
        SELECT d.campaign_id, @Day, greatest(d.impressions, 0), greatest(d.clicks, 0)
        FROM delta d
        WHERE d.impressions > 0 OR d.clicks > 0
        ORDER BY d.campaign_id
        ON CONFLICT (campaign_id, day) DO UPDATE
        SET impressions = s.impressions + EXCLUDED.impressions,
            clicks      = s.clicks + EXCLUDED.clicks;
        """;

    public async Task RecordAsync(
        Guid userId,
        DateTimeOffset nowUtc,
        DateOnly istDay,
        IReadOnlyList<PromotionDelivery> deliveries,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(deliveries);

        // One row per campaign: a duplicate in one INSERT would fail with "ON CONFLICT DO UPDATE command cannot
        // affect row a second time".
        var merged = deliveries
            .GroupBy(d => d.CampaignId)
            .Select(g => (Id: g.Key, Impressions: g.Sum(d => Math.Max(0, d.Impressions)), Clicks: g.Sum(d => Math.Max(0, d.Clicks))))
            .Where(d => d.Impressions > 0 || d.Clicks > 0)
            .ToArray();
        if (merged.Length == 0)
        {
            return;
        }

        // Typed parameters: Npgsql infers uuid[] / int[] / date / timestamptz from the CLR types.
        NpgsqlParameter[] parameters =
        [
            new NpgsqlParameter<Guid>("UserId", userId),
            new NpgsqlParameter<DateTimeOffset>("NowUtc", nowUtc.ToUniversalTime()),
            new NpgsqlParameter<DateOnly>("Day", istDay),
            new NpgsqlParameter<Guid[]>("CampaignIds", merged.Select(d => d.Id).ToArray()),
            new NpgsqlParameter<int[]>("Impressions", merged.Select(d => d.Impressions).ToArray()),
            new NpgsqlParameter<int[]>("Clicks", merged.Select(d => d.Clicks).ToArray()),
            new NpgsqlParameter<int>("MaxImpressions", CampaignUserDailyCount.MaxImpressions),
            new NpgsqlParameter<int>("MaxClicks", CampaignUserDailyCount.MaxClicks),
        ];

        // Raw SQL only through parameters — the interpolated parts are compile-time table names.
        await dbContext.Database.ExecuteSqlRawAsync(Sql, parameters, cancellationToken);
    }
}
