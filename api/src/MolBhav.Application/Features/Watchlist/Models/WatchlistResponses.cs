using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Watchlist.Models;

/// <summary>One watched product (or variant), localized the same way as the catalog product list, with latest price enrichment for the home/watchlist screens.</summary>
public sealed record WatchlistItemResponse(
    Guid Id,
    ProductSummaryResponse Product,
    Guid? VariantId,
    string? VariantName,
    DateTimeOffset AddedAtUtc,
    decimal? LatestPrice,
    string? PriceUnitSymbol,
    decimal? PercentChange);
