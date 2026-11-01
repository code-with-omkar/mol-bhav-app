using Dapper;
using MolBhav.Application.Abstractions.Admin;
using MolBhav.Application.Features.Admin.Models;

namespace MolBhav.Infrastructure.Persistence.Read.Admin;

internal sealed class AdminDashboardReadService(IDbConnectionFactory connectionFactory) : IAdminDashboardReadService
{
    // One round trip, one row. Users exclude soft-deleted accounts; ad days are IST calendar days (campaign_daily_stats.day).
    private const string CountsSql = """
        SELECT
            (SELECT count(*) FROM identity.users WHERE NOT is_deleted)::int AS users_total,
            (SELECT count(*) FROM identity.users WHERE NOT is_deleted AND created_at_utc >= @Since)::int AS users_new,
            (SELECT count(*) FROM identity.users WHERE NOT is_deleted AND last_login_at_utc >= @Since)::int AS users_active,
            (SELECT count(*) FROM identity.users WHERE NOT is_deleted AND status = 'Suspended')::int AS users_suspended,
            (SELECT count(*) FROM identity.users WHERE NOT is_deleted AND subscription_tier = 'Pro')::int AS users_pro,
            (SELECT count(*) FROM identity.users WHERE NOT is_deleted AND subscription_tier = 'Free')::int AS users_free,
            COALESCE((SELECT sum(impressions) FROM promotions.campaign_daily_stats WHERE day = @Today), 0)::bigint AS impressions_today,
            COALESCE((SELECT sum(clicks) FROM promotions.campaign_daily_stats WHERE day = @Today), 0)::bigint AS clicks_today,
            COALESCE((SELECT sum(impressions) FROM promotions.campaign_daily_stats WHERE day BETWEEN @WeekStart AND @Today), 0)::bigint AS impressions_week,
            COALESCE((SELECT sum(clicks) FROM promotions.campaign_daily_stats WHERE day BETWEEN @WeekStart AND @Today), 0)::bigint AS clicks_week,
            (SELECT count(*) FROM promotions.campaigns WHERE status = 'Active')::int AS active_campaigns,
            (SELECT count(*) FROM monetization.rewarded_ad_views WHERE verified_at_utc >= @Since)::int AS rewarded_views,
            (SELECT count(*) FROM support.support_tickets WHERE status IN ('Open', 'InProgress'))::int AS open_tickets;
        """;

    public async Task<DashboardCounts> GetCountsAsync(DateOnly today, DateTimeOffset nowUtc, CancellationToken cancellationToken = default)
    {
        var args = new { Since = nowUtc.AddDays(-7), Today = today, WeekStart = today.AddDays(-6) };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var r = await connection.QuerySingleAsync<CountsRow>(new CommandDefinition(CountsSql, args, cancellationToken: cancellationToken));

        return new DashboardCounts(
            new AdminUsersSummary(r.UsersTotal, r.UsersNew, r.UsersActive, r.UsersSuspended, r.UsersPro, r.UsersFree),
            new AdminAdsSummary(
                r.ImpressionsToday,
                r.ClicksToday,
                r.ImpressionsWeek,
                r.ClicksWeek,
                // Click-through rate as a percentage, one decimal; 0 when nothing was shown.
                r.ImpressionsWeek == 0 ? 0 : Math.Round(100d * r.ClicksWeek / r.ImpressionsWeek, 1),
                r.ActiveCampaigns,
                r.RewardedViews),
            new AdminSupportSummary(r.OpenTickets));
    }

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class CountsRow
    {
        public int UsersTotal { get; init; }

        public int UsersNew { get; init; }

        public int UsersActive { get; init; }

        public int UsersSuspended { get; init; }

        public int UsersPro { get; init; }

        public int UsersFree { get; init; }

        public long ImpressionsToday { get; init; }

        public long ClicksToday { get; init; }

        public long ImpressionsWeek { get; init; }

        public long ClicksWeek { get; init; }

        public int ActiveCampaigns { get; init; }

        public int RewardedViews { get; init; }

        public int OpenTickets { get; init; }
    }
}
