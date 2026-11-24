namespace MolBhav.Application.Features.Catalog.Models;

/// <summary>Why a requested commodity was not added.</summary>
public enum FeedCommoditySkipReason
{
    /// <summary>The commodity is not in the source's saved feed list.</summary>
    NotInFeed = 0,

    /// <summary>A product with the code this commodity resolves to already exists, so prices already land on it.</summary>
    AlreadyInCatalog = 1,

    /// <summary>The name cannot be turned into a valid product code (it must start with a letter).</summary>
    CodeInvalid = 2,

    /// <summary>The catalog's name rules refused it (for example, it is too long).</summary>
    NameInvalid = 3,
}

public sealed record SkippedFeedCommodity(string Commodity, FeedCommoditySkipReason Reason);

/// <param name="Created">How many products were added.</param>
/// <param name="Skipped">The commodities that were not added, each with the reason.</param>
public sealed record ImportFeedProductsResponse(int Created, IReadOnlyList<SkippedFeedCommodity> Skipped);

/// <param name="PriceSourceId">The source whose feed list the commodities come from.</param>
/// <param name="SubCategoryId">The sub-category every added product goes under.</param>
/// <param name="DefaultUnitId">The unit every added product is priced in.</param>
/// <param name="Commodities">Commodity names from the feed list.</param>
public sealed record ImportFeedProductsRequest(
    Guid PriceSourceId,
    Guid SubCategoryId,
    Guid DefaultUnitId,
    IReadOnlyList<string>? Commodities);
