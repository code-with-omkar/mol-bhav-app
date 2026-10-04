using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Promotions;

namespace MolBhav.Application.Abstractions.Promotions;

public sealed record AdminCampaignFilter(CampaignStatus? Status, Guid? AdvertiserId, PageRequest Page);

/// <summary>Dapper read side for serving and reporting sponsored campaigns.</summary>
public interface IPromotionReadService
{
    /// <summary>
    /// The best campaign for this user and slot right now: active, inside its schedule, under today's cap, and
    /// targeting one of the user's categories in their state (or all states). Highest priority wins; ties go to
    /// the campaign with fewer impressions today, so equal sponsors rotate. <c>null</c> when none matches.
    /// </summary>
    Task<PromotionResponse?> FindForUserAsync(
        Guid userId, PromotionPlacement placement, DateTimeOffset nowUtc, DateOnly istDay, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AdvertiserResponse>> GetAdvertisersAsync(CancellationToken cancellationToken = default);

    Task<PagedResult<AdminCampaignResponse>> GetCampaignsAsync(
        AdminCampaignFilter filter, DateOnly istDay, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CampaignDailyStatResponse>> GetDailyStatsAsync(
        Guid campaignId, DateOnly from, DateOnly to, CancellationToken cancellationToken = default);
}

public sealed record PromotionDelivery(Guid CampaignId, int Impressions, int Clicks);

/// <summary>
/// Credits client-reported delivery to campaigns. Runs in the command's unit-of-work transaction, so a retried
/// attempt never counts twice.
/// </summary>
public interface IPromotionStatsWriter
{
    /// <summary>
    /// Credits only campaigns that are servable at <paramref name="nowUtc"/> and target <paramref name="userId"/>
    /// (anything else could never have been shown to them), and only up to the user's daily allowance per campaign
    /// (<see cref="CampaignUserDailyCount"/>), clicks never above impressions. Anything beyond that
    /// is dropped silently.
    /// </summary>
    Task RecordAsync(
        Guid userId,
        DateTimeOffset nowUtc,
        DateOnly istDay,
        IReadOnlyList<PromotionDelivery> deliveries,
        CancellationToken cancellationToken = default);
}
