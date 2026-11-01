using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Ingestion.Common;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Ingestion.Admin.RunIngestionJob;

/// <summary>
/// Runs one ingestion adapter for a <c>PriceSource</c> and persists every resolvable record as a <c>PriceRecord</c>
/// (the same path <c>RecordPriceCommandHandler</c> uses for manual entry — BRD §9). A record that fails to resolve
/// or validate becomes a <see cref="DataIngestionError"/> instead of aborting the whole run, so one bad row from the
/// source never blocks the rest. All in one transaction (<c>UnitOfWorkBehavior</c>): the job, its errors, and every
/// persisted price record commit together, and each persisted record's <c>PriceRecordedDomainEvent</c> reaches the
/// outbox in the same save — Alerting evaluates it exactly as it would a manually entered price.
/// </summary>
internal sealed partial class RunIngestionJobCommandHandler(
    IDataIngestionJobRepository jobs,
    IPriceSourceRepository sources,
    ISourceFeedOptionsRepository feedOptions,
    IIngestionSourceAdapter adapter,
    IngestionRecordWriter writer,
    TimeProvider timeProvider,
    ILogger<RunIngestionJobCommandHandler> logger) : ICommandHandler<RunIngestionJobCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(RunIngestionJobCommand request, CancellationToken cancellationToken)
    {
        var source = await sources.GetByIdAsync(request.PriceSourceId, cancellationToken);
        if (source is null)
        {
            return Error.NotFound("PriceSource.NotFound", "Price source not found.");
        }

        if (!source.IsActive)
        {
            return Error.Validation("PriceSource.Inactive", "Cannot run ingestion for an inactive price source.");
        }

        // Checked before a job is created, so a bad filter leaves nothing behind.
        var filter = IngestionFilter.Create(request.States, request.Commodities, request.Markets);
        if (filter.IsFailure)
        {
            return Result.Failure<CreatedResponse>(filter.Error);
        }

        var now = timeProvider.GetUtcNow();

        var asOfDate = request.AsOfDate ?? IngestionDates.DefaultAsOf(now);
        var jobResult = DataIngestionJob.Start(source.Id, request.TriggerType, request.TriggeredByUserId, asOfDate, now);
        if (jobResult.IsFailure)
        {
            return Result.Failure<CreatedResponse>(jobResult.Error);
        }

        var job = jobResult.Value;
        jobs.Add(job);

        var fetch = await adapter.FetchAsync(new IngestionFetchRequest(source.Code, asOfDate, filter.Value), cancellationToken);
        if (!fetch.IsSuccess)
        {
            job.MarkAdapterFailed(fetch.FailureReason ?? "Ingestion adapter failed with no reason given.", timeProvider.GetUtcNow());
            return new CreatedResponse(job.Id);
        }

        // A source's API serves its whole feed (Agmarknet: every commodity in every market in India). Rows for products or
        // locations the catalog does not have are dropped rather than stored as thousands of errors per run; the job's
        // counts cover the rows that matched the catalog. Likewise a feed names far more varieties than the catalog
        // tracks, so an unknown variety is stored as the product's no-variant price rather than rejected.
        // A full pull saw the whole feed: remember which states, markets and commodities it has (filter dropdowns).
        if (fetch.FeedNames is { } names)
        {
            var existing = await feedOptions.GetByPriceSourceIdAsync(source.Id, cancellationToken);
            if (existing is not null)
            {
                existing.Replace(names.Commodities, names.Markets, timeProvider.GetUtcNow());
            }
            else if (SourceFeedOptions.Create(source.Id, names.Commodities, names.Markets, timeProvider.GetUtcNow()) is { IsSuccess: true } created)
            {
                feedOptions.Add(created.Value);
            }
        }

        var counts = await writer.WriteAsync(
            job, source.CategoryId, fetch.Records, cancellationToken, skipRowsOutsideCatalog: true, fallbackToProductForUnknownVariety: true);
        job.Complete(counts.Fetched, counts.Persisted, counts.Unchanged, counts.Failed, timeProvider.GetUtcNow());
        LogSkipped(logger, source.Code, asOfDate, counts.Skipped, fetch.Records.Count);
        return new CreatedResponse(job.Id);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Ingestion {SourceCode} {AsOfDate}: skipped {Skipped} of {Total} rows (outside the catalog, or another unknown variety of a price already stored)")]
    private static partial void LogSkipped(ILogger logger, string sourceCode, DateOnly asOfDate, int skipped, int total);
}
