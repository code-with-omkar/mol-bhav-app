namespace MolBhav.Domain.Promotions;

/// <summary>Where a sponsored card can appear. Stored as text, so members may be added but never renamed.</summary>
public enum PromotionPlacement
{
    /// <summary>Home, between Top Opportunity and My Watchlist.</summary>
    HomeFeed = 0,

    /// <summary>Mandi prices, between the first two groups of rows.</summary>
    MandiPrices = 1,

    /// <summary>Market Comparison, below the source note.</summary>
    MarketComparison = 2,
}
