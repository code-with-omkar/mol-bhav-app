using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Ingestion.Admin.BackfillIngestion;

internal sealed class BackfillIngestionCommandHandler(
    IPriceSourceRepository sources,
    IIngestionBackfillQueue queue,
    TimeProvider timeProvider) : ICommandHandler<BackfillIngestionCommand, BackfillQueuedResponse>
{
    public async Task<Result<BackfillQueuedResponse>> Handle(BackfillIngestionCommand request, CancellationToken cancellationToken)
    {
        if (request.FromDate is not { } from || request.ToDate is not { } to)
        {
            return Error.Validation("Ingestion.BackfillRange", "fromDate and toDate are required.");
        }

        var source = await sources.GetByIdAsync(request.PriceSourceId, cancellationToken);
        if (source is null)
        {
            return Error.NotFound("PriceSource.NotFound", "Price source not found.");
        }

        if (!source.IsActive)
        {
            return Error.Validation("PriceSource.Inactive", "Cannot run ingestion for an inactive price source.");
        }

        if (to > IngestionDates.TodayIst(timeProvider.GetUtcNow()))
        {
            return Error.Validation("Ingestion.BackfillFuture", "toDate cannot be in the future (IST).");
        }

        var dates = Enumerable.Range(0, to.DayNumber - from.DayNumber + 1).Select(from.AddDays).ToArray();
        if (!queue.TryEnqueue(new IngestionBackfillRequest([source.Id], request.RequestedByUserId, dates)))
        {
            return Error.Conflict("Ingestion.BackfillBusy", "Too many backfills are waiting. Try again when the current ones finish.");
        }

        return new BackfillQueuedResponse(dates.Length, from, to);
    }
}
