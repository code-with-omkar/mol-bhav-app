using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Admin.Models;

/// <summary>The admin app's landing screen: headline numbers across users, ads, the price feeds and support.</summary>
public sealed record AdminDashboardResponse(
    AdminUsersSummary Users,
    AdminAdsSummary Ads,
    AdminFeedsSummary Feeds,
    AdminSupportSummary Support,
    DateTimeOffset GeneratedAtUtc);

/// <param name="Total">Signed-up users (deleted ones excluded).</param>
/// <param name="NewLast7Days">Signed up in the last 7 days.</param>
/// <param name="ActiveLast7Days">Logged in during the last 7 days.</param>
public sealed record AdminUsersSummary(int Total, int NewLast7Days, int ActiveLast7Days, int Suspended, int Pro, int Free);

/// <summary>
/// Sponsored-campaign delivery (our own ad slots, tracked by <c>POST /promotions/events</c>) plus verified rewarded-ad views.
/// Clicks on AdMob banners are only visible in AdMob itself. Days are IST.
/// </summary>
public sealed record AdminAdsSummary(
    long ImpressionsToday,
    long ClicksToday,
    long Impressions7Days,
    long Clicks7Days,
    double ClickRate7DaysPercent,
    int ActiveCampaigns,
    int RewardedViews7Days);

/// <summary>Health of the automatically refreshed price feeds (same rule as the app's "prices delayed" banner).</summary>
public sealed record AdminFeedsSummary(
    bool IsDelayed,
    DateTimeOffset? LastSuccessAtUtc,
    IngestionJobStatus? LastAttemptStatus,
    DateTimeOffset? LastAttemptAtUtc);

/// <param name="OpenTickets">Tickets still open or in progress.</param>
public sealed record AdminSupportSummary(int OpenTickets);
