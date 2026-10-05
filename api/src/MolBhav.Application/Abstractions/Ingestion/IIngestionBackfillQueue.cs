namespace MolBhav.Application.Abstractions.Ingestion;

/// <summary>
/// Hands a backfill to the background worker, which runs one ingestion job per date in its own transaction —
/// a month of mandi data is far too much for one request or one transaction.
/// In-process: a backfill queued but not yet run is lost on restart; the admin simply requests it again.
/// </summary>
public interface IIngestionBackfillQueue
{
    /// <summary>False when the queue is full (too many backfills waiting).</summary>
    bool TryEnqueue(IngestionBackfillRequest request);
}

/// <summary>
/// One queued unit of work: every date (oldest first) for each source in turn. A single-source backfill has one id;
/// a category "run all" has every active source of that category for one date — one queue slot either way.
/// </summary>
public sealed record IngestionBackfillRequest(IReadOnlyList<Guid> PriceSourceIds, Guid RequestedByUserId, IReadOnlyList<DateOnly> Dates);
