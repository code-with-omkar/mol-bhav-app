namespace MolBhav.Application.Features.Market.Models;

/// <summary>Why a requested market was not added.</summary>
public enum FeedMarketSkipReason
{
    /// <summary>The market is not in the source's saved feed list for that state.</summary>
    NotInFeed = 0,

    /// <summary>A mandi with the code this market resolves to already exists, so prices already land on it.</summary>
    AlreadyInCatalog = 1,

    /// <summary>The name cannot be turned into a valid mandi code (it must start with a letter, 40 characters at most).</summary>
    CodeInvalid = 2,

    /// <summary>The feed gave no district for the market, so it cannot be placed.</summary>
    DistrictUnknown = 3,

    /// <summary>The market or its district was refused by the catalog's name rules.</summary>
    NameInvalid = 4,
}

public sealed record SkippedFeedMarket(string Market, FeedMarketSkipReason Reason);

/// <param name="Created">How many mandis were added.</param>
/// <param name="Skipped">The markets that were not added, each with the reason.</param>
public sealed record ImportFeedMarketsResponse(int Created, IReadOnlyList<SkippedFeedMarket> Skipped);

/// <param name="PriceSourceId">The source whose feed list the markets come from.</param>
/// <param name="State">The state, spelled as in the feed list.</param>
/// <param name="Markets">Market names from that state's feed list.</param>
public sealed record ImportFeedMarketsRequest(Guid PriceSourceId, string? State, IReadOnlyList<string>? Markets);
