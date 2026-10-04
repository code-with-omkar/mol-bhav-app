using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Monetization;
using MolBhav.Application.Abstractions.Watchlist;
using MolBhav.Application.Features.Monetization.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Monetization;

namespace MolBhav.Application.Features.Monetization;

/// <summary>
/// Two concurrent adds can each see one free slot and both succeed, overshooting the cap by one. That is accepted:
/// the cap is a nudge towards Pro, not a security boundary, and serialising every add would cost more than it saves.
/// </summary>
internal sealed class EntitlementService(
    ICurrentUser currentUser,
    IFreeTierPolicy policy,
    IFeatureGrantRepository grants,
    IWatchlistItemRepository watchlistItems,
    IAlertRuleRepository alertRules,
    TimeProvider timeProvider) : IEntitlementService
{
    private bool IsPro => string.Equals(currentUser.SubscriptionTier, SubscriptionTiers.Pro, StringComparison.OrdinalIgnoreCase);

    public async Task<Result> EnsureCanAddAsync(MonetizedFeature slotFeature, CancellationToken cancellationToken)
    {
        if (IsPro)
        {
            return Result.Success();
        }

        var userId = currentUser.GetRequiredUserId();
        var (used, capacity, _) = await SlotUsageAsync(userId, slotFeature, cancellationToken);

        if (used < capacity)
        {
            return Result.Success();
        }

        return slotFeature == MonetizedFeature.WatchlistSlots
            ? MonetizationErrors.WatchlistLimitReached
            : MonetizationErrors.AlertRuleLimitReached;
    }

    public async Task<Result> AuthorizeProReportAsync(CancellationToken cancellationToken)
    {
        if (IsPro)
        {
            return Result.Success();
        }

        var userId = currentUser.GetRequiredUserId();
        var now = timeProvider.GetUtcNow();
        var usable = await grants.GetUsableAsync(userId, MonetizedFeature.PriceHistoryReport, now, cancellationToken);

        return usable.Count == 0
            ? MonetizationErrors.ReportProRequired
            : usable[0].Consume(now);
    }

    public async Task<Result> EnsureCanStartUnlockAsync(MonetizedFeature feature, CancellationToken cancellationToken)
    {
        if (IsPro)
        {
            return MonetizationErrors.UnlockNotNeeded;
        }

        var userId = currentUser.GetRequiredUserId();
        var limits = policy.Limits;

        if (FreeTierLimits.IsSlotFeature(feature))
        {
            var unlocked = await grants.SumQuantityAsync(userId, feature, cancellationToken);
            return limits.SlotsFor(feature).CanUnlockMore(unlocked)
                ? Result.Success()
                : MonetizationErrors.UnlockLimitReached;
        }

        var unlocksLeft = await ReportUnlocksLeftTodayAsync(userId, cancellationToken);
        return unlocksLeft > 0 ? Result.Success() : MonetizationErrors.UnlockLimitReached;
    }

    public async Task<EntitlementsResponse> GetAsync(CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        var limits = policy.Limits;
        var isPro = IsPro;

        var watchlist = await SlotResponseAsync(userId, MonetizedFeature.WatchlistSlots, isPro, cancellationToken);
        var alertRules = await SlotResponseAsync(userId, MonetizedFeature.AlertRuleSlots, isPro, cancellationToken);

        ReportEntitlementResponse reports;
        if (isPro)
        {
            reports = new ReportEntitlementResponse(0, 0, limits.PriceHistoryReports.AdsPerUnlock, CanUnlockWithAds: false);
        }
        else
        {
            var usable = await grants.GetUsableAsync(userId, MonetizedFeature.PriceHistoryReport, timeProvider.GetUtcNow(), cancellationToken);
            var left = await ReportUnlocksLeftTodayAsync(userId, cancellationToken);
            reports = new ReportEntitlementResponse(usable.Count, left, limits.PriceHistoryReports.AdsPerUnlock, CanUnlockWithAds: left > 0);
        }

        return new EntitlementsResponse(isPro, watchlist, alertRules, reports);
    }

    private async Task<SlotEntitlementResponse> SlotResponseAsync(
        Guid userId, MonetizedFeature feature, bool isPro, CancellationToken cancellationToken)
    {
        var allowance = policy.Limits.SlotsFor(feature);
        var (used, capacity, unlocked) = await SlotUsageAsync(userId, feature, cancellationToken);

        return isPro
            ? new SlotEntitlementResponse(used, Limit: null, Maximum: null, allowance.PerUnlock, allowance.AdsPerUnlock, CanUnlockWithAds: false)
            : new SlotEntitlementResponse(used, capacity, allowance.Maximum, allowance.PerUnlock, allowance.AdsPerUnlock, allowance.CanUnlockMore(unlocked));
    }

    private async Task<(int Used, int Capacity, int Unlocked)> SlotUsageAsync(
        Guid userId, MonetizedFeature feature, CancellationToken cancellationToken)
    {
        var used = feature switch
        {
            MonetizedFeature.WatchlistSlots => await watchlistItems.CountByUserAsync(userId, cancellationToken),
            MonetizedFeature.AlertRuleSlots => await alertRules.CountByUserAsync(userId, cancellationToken),
            _ => throw new ArgumentOutOfRangeException(nameof(feature), feature, "Not a slot-based feature."),
        };

        var unlocked = await grants.SumQuantityAsync(userId, feature, cancellationToken);
        return (used, policy.Limits.SlotsFor(feature).Capacity(unlocked), unlocked);
    }

    private async Task<int> ReportUnlocksLeftTodayAsync(Guid userId, CancellationToken cancellationToken)
    {
        var since = IndiaDay.StartUtc(timeProvider.GetUtcNow());
        var grantedToday = await grants.CountGrantedSinceAsync(
            userId, MonetizedFeature.PriceHistoryReport, source: null, since, cancellationToken);

        return Math.Max(0, policy.Limits.PriceHistoryReports.UnlocksPerDay - grantedToday);
    }
}
