using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.FeatureSwitches;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Application.Features.Monetization;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.FeatureSwitches;

namespace MolBhav.Application.Features.Promotions.GetPromotion;

/// <summary>
/// Pro users bought an ad-free app: they never get a sponsored card either. Nobody gets one while an admin has the Ads
/// feature switched off, so older app builds (which do not know the switch) stop showing sponsors too.
/// </summary>
internal sealed class GetPromotionQueryHandler(
    IPromotionReadService readService,
    IFeatureSwitchRepository featureSwitches,
    ICurrentUser currentUser,
    TimeProvider timeProvider)
    : IQueryHandler<GetPromotionQuery, PromotionSlotResponse>
{
    public async Task<Result<PromotionSlotResponse>> Handle(GetPromotionQuery request, CancellationToken cancellationToken)
    {
        if (string.Equals(currentUser.SubscriptionTier, SubscriptionTiers.Pro, StringComparison.OrdinalIgnoreCase)
            || !await featureSwitches.IsEnabledAsync(AppFeature.Ads, cancellationToken))
        {
            return new PromotionSlotResponse(null);
        }

        var now = timeProvider.GetUtcNow();
        var promotion = await readService.FindForUserAsync(
            currentUser.GetRequiredUserId(), request.Placement!.Value, now, IndiaDay.Today(now), cancellationToken);

        return new PromotionSlotResponse(promotion);
    }
}
