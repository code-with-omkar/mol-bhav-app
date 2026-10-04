using MolBhav.Application.Features.Promotions.Admin;
using MolBhav.Application.Features.Promotions.Admin.SetCampaignStatus;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Promotions;

namespace MolBhav.Api.Contracts.Promotions;

/// <summary>One sponsored-card event the app saw: the card was shown (<c>Impression</c>) or its button tapped (<c>Click</c>).</summary>
public sealed record PromotionEventRequest(Guid CampaignId, PromotionEventType? Type);

/// <summary>Up to 50 events batched by the app since its last report.</summary>
public sealed record RecordPromotionEventsRequest(IReadOnlyList<PromotionEventRequest>? Events)
{
    public IReadOnlyList<PromotionEventInput>? ToInputs() =>
        Events?.Select(e => new PromotionEventInput(e.CampaignId, e.Type)).ToArray();
}

/// <summary>Create and update share this shape; <c>Gstin</c> is the 15-character GST number.</summary>
public sealed record AdvertiserRequest(string? Name, string? ContactName, string? ContactPhone, string? Gstin);

/// <summary>A category (with an optional state; none = every state) the campaign is shown to.</summary>
public sealed record CampaignTargetRequest(string? CategoryCode, Guid? StateId);

/// <summary>Everything editable on a campaign. Links must be https; times are UTC.</summary>
public sealed record CampaignRequest(
    string? Name,
    PromotionPlacement? Placement,
    string? Title,
    string? Body,
    string? CtaLabel,
    string? CtaUrl,
    string? ImageUrl,
    DateTimeOffset? StartsAtUtc,
    DateTimeOffset? EndsAtUtc,
    int? Priority,
    int? DailyImpressionCap,
    IReadOnlyList<CampaignTargetRequest>? Targets)
{
    public CampaignInput ToInput() => new(
        Name,
        Placement,
        Title,
        Body,
        CtaLabel,
        CtaUrl,
        ImageUrl,
        StartsAtUtc,
        EndsAtUtc,
        Priority,
        DailyImpressionCap,
        Targets?.Select(t => new CampaignTargetInput(t.CategoryCode, t.StateId)).ToArray());
}

/// <summary>Creates the campaign as <c>Draft</c> under <see cref="AdvertiserId"/>.</summary>
public sealed record CreateCampaignRequest(Guid? AdvertiserId, CampaignRequest? Campaign);

public sealed record SetCampaignStatusRequest(CampaignStatusAction? Action);
