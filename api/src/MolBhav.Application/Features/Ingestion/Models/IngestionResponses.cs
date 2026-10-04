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

/// <summary>
/// One price source as the admin schedule screen shows it. <paramref name="IsConfigured"/> is false (and every schedule
/// field null) for a source that has never been scheduled — the scheduler never runs it automatically.
/// <paramref name="TimeOfDay"/> is IST wall-clock <c>HH:mm</c>.
/// </summary>
public sealed record AdminIngestionScheduleResponse(
    Guid PriceSourceId,
    string PriceSourceCode,
    string PriceSourceName,
    bool PriceSourceIsActive,
    bool IsConfigured,
    bool IsEnabled,
    IngestionScheduleFrequency? Frequency,
    string? TimeOfDay,
    DayOfWeek? DayOfWeek,
    int? IntervalHours,
    DateTimeOffset? NextRunAtUtc,
    DateTimeOffset? LastRunAtUtc,
    AdminIngestionLastJobResponse? LastJob);

/// <summary>The source's most recent job, manual or scheduled.</summary>
public sealed record AdminIngestionLastJobResponse(
    Guid Id,
    IngestionTriggerType TriggerType,
    IngestionJobStatus Status,
    int RecordsPersisted,
    int RecordsFailed,
    string? FailureReason,
    DateTimeOffset StartedAtUtc,
    DateTimeOffset? CompletedAtUtc);
