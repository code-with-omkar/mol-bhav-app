namespace MolBhav.Domain.Monetization;

/// <summary>
/// A free-tier capability that is capped and can be extended by watching rewarded ads. Pro users are never capped.
/// Stored as text (enum-as-string convention), so members may be added but never renamed.
/// </summary>
public enum MonetizedFeature
{
    /// <summary>Extra watchlist slots, kept for good once unlocked.</summary>
    WatchlistSlots = 0,

    /// <summary>Extra alert-rule slots, kept for good once unlocked.</summary>
    AlertRuleSlots = 1,

    /// <summary>One Pro-only price-history report, valid for a limited time and consumed when requested.</summary>
    PriceHistoryReport = 2,
}
