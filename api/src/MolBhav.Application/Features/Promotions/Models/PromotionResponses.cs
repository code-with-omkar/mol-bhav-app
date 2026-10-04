using MolBhav.Domain.Promotions;

namespace MolBhav.Application.Features.Promotions.Models;

/// <summary>What the app renders as a "Sponsored" card.</summary>
public sealed record PromotionResponse(
    Guid CampaignId,
    string AdvertiserName,
    string Title,
    string Body,
    string CtaLabel,
    string CtaUrl,
    string? ImageUrl);

/// <summary><see cref="Promotion"/> is <c>null</c> when nothing is booked for this user and slot — the app then
/// falls back to an AdMob native ad.</summary>
public sealed record PromotionSlotResponse(PromotionResponse? Promotion);

public enum PromotionEventType
{
    Impression = 0,
    Click = 1,
}

public sealed record PromotionEventInput(Guid CampaignId, PromotionEventType? Type);

public sealed record AdvertiserResponse(Guid Id, string Name, string? ContactName, string? ContactPhone, string? Gstin, int ActiveCampaigns);

public sealed record AdminCampaignResponse(
    Guid Id,
    Guid AdvertiserId,
    string AdvertiserName,
    string Name,
    PromotionPlacement Placement,
    CampaignStatus Status,
    DateTimeOffset StartsAtUtc,
    DateTimeOffset EndsAtUtc,
    int Priority,
    int? DailyImpressionCap,
    string Title,
    string Body,
    string CtaLabel,
    string CtaUrl,
    string? ImageUrl,
    IReadOnlyList<CampaignTargetResponse> Targets,
    long ImpressionsToday,
    long ClicksToday,
    long ImpressionsTotal,
    long ClicksTotal);

public sealed record CampaignTargetResponse(string CategoryCode, Guid? StateId);

public sealed record CampaignDailyStatResponse(DateOnly Day, long Impressions, long Clicks);

public sealed record CampaignTargetInput(string? CategoryCode, Guid? StateId);
