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
internal sealed class RunIngestionJobCommandHandler(
    IDataIngestionJobRepository jobs,
    IPriceSourceRepository sources,
    IIngestionSourceAdapter adapter,
    IngestionRecordWriter writer,
    TimeProvider timeProvider) : ICommandHandler<RunIngestionJobCommand, CreatedResponse>
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

        var now = timeProvider.GetUtcNow();

        var asOfDate = request.AsOfDate ?? IngestionDates.DefaultAsOf(now);
        var jobResult = DataIngestionJob.Start(source.Id, request.TriggerType, request.TriggeredByUserId, asOfDate, now);
        if (jobResult.IsFailure)
        {
            return Result.Failure<CreatedResponse>(jobResult.Error);
        }

        var job = jobResult.Value;
        jobs.Add(job);

        var fetch = await adapter.FetchAsync(new IngestionFetchRequest(source.Code, asOfDate), cancellationToken);
        if (!fetch.IsSuccess)
        {
            job.MarkAdapterFailed(fetch.FailureReason ?? "Ingestion adapter failed with no reason given.", timeProvider.GetUtcNow());
            return new CreatedResponse(job.Id);
        }

        var counts = await writer.WriteAsync(job, source.CategoryId, fetch.Records, cancellationToken);
        job.Complete(counts.Fetched, counts.Persisted, counts.Unchanged, counts.Failed, timeProvider.GetUtcNow());
        return new CreatedResponse(job.Id);
    }
}
