using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Ingestion.Admin.BackfillIngestion;

/// <summary>Queues one ingestion run per date from <paramref name="FromDate"/> to <paramref name="ToDate"/> (inclusive, IST dates).</summary>
public sealed record BackfillIngestionCommand(
    Guid PriceSourceId,
    DateOnly? FromDate,
    DateOnly? ToDate,
    Guid RequestedByUserId) : ICommand<BackfillQueuedResponse>;

/// <summary>How many daily runs were queued; each shows up as a job as it finishes.</summary>
public sealed record BackfillQueuedResponse(int Days, DateOnly FromDate, DateOnly ToDate);
