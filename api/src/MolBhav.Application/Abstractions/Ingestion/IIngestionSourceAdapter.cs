using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Abstractions.Ingestion;

/// <summary>
/// Pulls and normalizes price data from one external source (BRD §9: an Agmarknet/data.gov.in adapter for
/// agriculture, a WPI/CPWD/data.gov.in adapter for construction, or any future feed) — "category-specific adapters
/// must map into a common normalized price model" (BRD §9), which is exactly <see cref="IngestedPriceRecord"/>.
/// Resolved once per <c>PriceSource.Code</c> by the registered implementation. Until a real HTTP client for a given
/// source is wired up, the registered implementation (<c>StubIngestionSourceAdapter</c>) always returns a failed
/// outcome with an honest, specific reason rather than fabricating data.
/// </summary>
public interface IIngestionSourceAdapter
{
    Task<IngestionFetchResult> FetchAsync(IngestionFetchRequest request, CancellationToken cancellationToken = default);
}

/// <summary><paramref name="AsOfDate"/> is the trading/publication date the adapter should fetch — usually "today" for a scheduled run.</summary>
/// <param name="SourceCode">The price source being pulled.</param>
/// <param name="AsOfDate">The market day to pull.</param>
/// <param name="Filter">What to ask the source for (from the source's schedule); null = everything.</param>
public sealed record IngestionFetchRequest(string SourceCode, DateOnly AsOfDate, IngestionFilter? Filter = null);

/// <summary>Names seen in a feed, spelled as the source spells them.</summary>
public sealed record FeedNames(IReadOnlyList<string> Commodities, IReadOnlyList<FeedMarket> Markets);

public sealed record IngestionFetchResult
{
    private IngestionFetchResult(bool isSuccess, string? failureReason, IReadOnlyList<IngestedPriceRecord> records, FeedNames? feedNames = null)
    {
        IsSuccess = isSuccess;
        FailureReason = failureReason;
        Records = records;
        FeedNames = feedNames;
    }

    /// <summary>
    /// The states/markets/commodities the feed contained, set only by a full (unfiltered) pull that saw the whole feed —
    /// a filtered pull sees a slice and must not overwrite the full picture. Feeds the admin app's filter dropdowns.
    /// </summary>
    public FeedNames? FeedNames { get; }

    /// <summary>False when the adapter itself could not run at all (source unreachable, feed format changed, not configured). A partial/empty fetch that did run is still a success with zero records.</summary>
    public bool IsSuccess { get; }

    public string? FailureReason { get; }

    public IReadOnlyList<IngestedPriceRecord> Records { get; }

    public static IngestionFetchResult Success(IReadOnlyList<IngestedPriceRecord> records, FeedNames? feedNames = null) =>
        new(true, null, records, feedNames);

    public static IngestionFetchResult Failed(string reason) => new(false, reason, []);
}

/// <summary>
/// One normalized row from an external feed, keyed by the same immutable codes the admin portal uses
/// (<c>CatalogCode</c>/<c>MarketCode</c> — "ingestion adapters map source location names onto it") — resolved to
/// internal ids by the command handler, one row at a time, so a single unmapped code fails only that row.
/// </summary>
public sealed record IngestedPriceRecord(
    string ProductCode,
    string? VariantCode,
    LocationKind LocationKind,
    string LocationCode,
    decimal? MinPrice,
    decimal? MaxPrice,
    decimal ModalPrice,
    decimal? ArrivalQuantity,
    DateOnly RecordDate);
