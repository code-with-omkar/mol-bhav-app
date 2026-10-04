namespace MolBhav.Domain.Monetization;

/// <summary>
/// A capacity-based allowance (watchlist items, alert rules): <see cref="Included"/> for free, then
/// <see cref="PerUnlock"/> more for every <see cref="AdsPerUnlock"/> rewarded ads, never beyond <see cref="Maximum"/>.
/// Unlocked slots are kept for good, so capacity only grows.
/// </summary>
public sealed record SlotAllowance(int Included, int PerUnlock, int Maximum, int AdsPerUnlock)
{
    public bool IsValid => Included >= 0 && PerUnlock >= 1 && Maximum >= Included && AdsPerUnlock >= 1;

    /// <summary>Usable capacity after <paramref name="unlockedSlots"/> have been earned; capped at <see cref="Maximum"/>.</summary>
    public int Capacity(int unlockedSlots) => Math.Min(Maximum, Included + Math.Max(0, unlockedSlots));

    /// <summary>Whether watching more ads would still raise the capacity.</summary>
    public bool CanUnlockMore(int unlockedSlots) => Capacity(unlockedSlots) < Maximum;
}

/// <summary>
/// A per-use allowance for Pro-only reports: each unlock (<see cref="AdsPerUnlock"/> ads) allows one report within
/// <see cref="UnlockLifetime"/>, at most <see cref="UnlocksPerDay"/> times a day so heavy users still see value in Pro.
/// </summary>
public sealed record ReportAllowance(int AdsPerUnlock, int UnlocksPerDay, TimeSpan UnlockLifetime)
{
    public bool IsValid => AdsPerUnlock >= 1 && UnlocksPerDay >= 1 && UnlockLifetime > TimeSpan.Zero;
}

/// <summary>
/// The free-tier rules (BRD §23: "pricing and entitlement rules should be configurable rather than hard-coded").
/// Bound from configuration in Infrastructure; this type owns the arithmetic so every caller applies it the same way.
/// </summary>
public sealed record FreeTierLimits(
    SlotAllowance Watchlist,
    SlotAllowance AlertRules,
    ReportAllowance PriceHistoryReports,
    int NoFillGrantsPerDay,
    TimeSpan UnlockSessionLifetime)
{
    public bool IsValid =>
        Watchlist is { IsValid: true }
        && AlertRules is { IsValid: true }
        && PriceHistoryReports is { IsValid: true }
        && NoFillGrantsPerDay >= 0
        && UnlockSessionLifetime > TimeSpan.Zero;

    public SlotAllowance SlotsFor(MonetizedFeature feature) => feature switch
    {
        MonetizedFeature.WatchlistSlots => Watchlist,
        MonetizedFeature.AlertRuleSlots => AlertRules,
        _ => throw new ArgumentOutOfRangeException(nameof(feature), feature, "Not a slot-based feature."),
    };

    public int AdsRequiredFor(MonetizedFeature feature) => feature switch
    {
        MonetizedFeature.WatchlistSlots => Watchlist.AdsPerUnlock,
        MonetizedFeature.AlertRuleSlots => AlertRules.AdsPerUnlock,
        MonetizedFeature.PriceHistoryReport => PriceHistoryReports.AdsPerUnlock,
        _ => throw new ArgumentOutOfRangeException(nameof(feature), feature, "Unknown monetized feature."),
    };

    /// <summary>What one completed unlock is worth: slots for capacity features, one time-limited report otherwise.</summary>
    public (int Quantity, TimeSpan? Lifetime) GrantTermsFor(MonetizedFeature feature) => feature switch
    {
        MonetizedFeature.WatchlistSlots => (Watchlist.PerUnlock, null),
        MonetizedFeature.AlertRuleSlots => (AlertRules.PerUnlock, null),
        MonetizedFeature.PriceHistoryReport => (1, PriceHistoryReports.UnlockLifetime),
        _ => throw new ArgumentOutOfRangeException(nameof(feature), feature, "Unknown monetized feature."),
    };

    public static bool IsSlotFeature(MonetizedFeature feature) =>
        feature is MonetizedFeature.WatchlistSlots or MonetizedFeature.AlertRuleSlots;
}
