using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Ingestion.Models;

public sealed record AdminIngestionJobResponse(
    Guid Id,
    Guid PriceSourceId,
    string PriceSourceCode,
    IngestionTriggerType TriggerType,
    Guid? TriggeredByUserId,
    IngestionJobStatus Status,
    int RecordsFetched,
    int RecordsPersisted,
    int RecordsFailed,
    string? FailureReason,
    DateTimeOffset StartedAtUtc,
    DateTimeOffset? CompletedAtUtc);

public sealed record AdminIngestionErrorResponse(
    Guid Id,
    Guid JobId,
    string RawPayload,
    string ErrorMessage,
    DateTimeOffset OccurredAtUtc);
