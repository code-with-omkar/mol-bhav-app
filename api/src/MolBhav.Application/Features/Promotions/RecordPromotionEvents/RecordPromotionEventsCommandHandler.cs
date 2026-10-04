using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Application.Features.Monetization;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Promotions.RecordPromotionEvents;

/// <summary>
/// Counts are client-reported, so they are bounded three ways: at most <see cref="MaxImpressionsPerCampaign"/>
/// impressions and <see cref="MaxClicksPerCampaign"/> clicks per campaign per request, a per-user daily allowance per
/// campaign enforced by the writer, and the per-user rate limit. Pro users are never served sponsors, so their
/// reports are ignored.
/// </summary>
internal sealed class RecordPromotionEventsCommandHandler(
    IPromotionStatsWriter writer,
    ICurrentUser currentUser,
    TimeProvider timeProvider)
    : ICommandHandler<RecordPromotionEventsCommand>
{
    public const int MaxImpressionsPerCampaign = 10;
    public const int MaxClicksPerCampaign = 3;

    public async Task<Result> Handle(RecordPromotionEventsCommand request, CancellationToken cancellationToken)
    {
        if (string.Equals(currentUser.SubscriptionTier, SubscriptionTiers.Pro, StringComparison.OrdinalIgnoreCase))
        {
            return Result.Success();
        }

        var deliveries = request.Events!
            .GroupBy(e => e.CampaignId)
            .Select(g => new PromotionDelivery(
                g.Key,
                Math.Min(MaxImpressionsPerCampaign, g.Count(e => e.Type == PromotionEventType.Impression)),
                Math.Min(MaxClicksPerCampaign, g.Count(e => e.Type == PromotionEventType.Click))))
            .Where(d => d.Impressions > 0 || d.Clicks > 0)
            .ToList();

        if (deliveries.Count > 0)
        {
            var now = timeProvider.GetUtcNow();
            await writer.RecordAsync(currentUser.GetRequiredUserId(), now, IndiaDay.Today(now), deliveries, cancellationToken);
        }

        return Result.Success();
    }
}
