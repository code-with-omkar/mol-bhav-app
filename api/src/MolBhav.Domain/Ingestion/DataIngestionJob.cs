using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Ingestion;

/// <summary>
/// One run of an ingestion adapter against a <c>PriceSource</c> (BRD §9/§19: DataIngestionJobs) — Agmarknet/data.gov.in
/// for agriculture, WPI/CPWD for construction, or any future feed, all mapping into the same normalized
/// <c>PriceRecord</c> model rather than forking by category (BRD §20). Until a real adapter is wired up behind
/// <c>IIngestionSourceAdapter</c>, every run ends <see cref="IngestionJobStatus.Failed"/> with an honest reason
/// (data model + admin CRUD only, per scope) — never a fabricated success. Never deleted: ingestion history/audit.
/// </summary>
public sealed class DataIngestionJob : AggregateRoot<Guid>, IAuditableEntity
{
    public const int FailureReasonMaxLength = 500;

    private DataIngestionJob(
        Guid id, Guid priceSourceId, IngestionTriggerType triggerType, Guid? triggeredByUserId, DateOnly asOfDate, DateTimeOffset startedAtUtc)
        : base(id)
    {
        PriceSourceId = priceSourceId;
        AsOfDate = asOfDate;
        TriggerType = triggerType;
        TriggeredByUserId = triggeredByUserId;
        Status = IngestionJobStatus.Running;
        StartedAtUtc = startedAtUtc;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private DataIngestionJob()
    {
    }

    public Guid PriceSourceId { get; private set; }

    public IngestionTriggerType TriggerType { get; private set; }

    /// <summary>The admin who triggered a <see cref="IngestionTriggerType.Manual"/> run; null for <see cref="IngestionTriggerType.Scheduled"/>.</summary>
    public Guid? TriggeredByUserId { get; private set; }

    public IngestionJobStatus Status { get; private set; }

    /// <summary>The publication date this run pulled. Null only for jobs recorded before the column existed.</summary>
    public DateOnly? AsOfDate { get; private set; }

    public int RecordsFetched { get; private set; }

    public int RecordsPersisted { get; private set; }

    public int RecordsFailed { get; private set; }

    /// <summary>Rows the source sent again with identical figures — already stored, so left untouched.</summary>
    public int RecordsUnchanged { get; private set; }

    /// <summary>Set only when the adapter itself failed (source unreachable/not configured) — per-record failures live in <see cref="DataIngestionError"/> instead.</summary>
    public string? FailureReason { get; private set; }

    public DateTimeOffset StartedAtUtc { get; private set; }

    public DateTimeOffset? CompletedAtUtc { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<DataIngestionJob> Start(
        Guid priceSourceId, IngestionTriggerType triggerType, Guid? triggeredByUserId, DateOnly asOfDate, DateTimeOffset startedAtUtc)
    {
        if (priceSourceId == Guid.Empty)
        {
            return Error.Validation("DataIngestionJob.PriceSourceRequired", "Price source is required.");
        }

        if (triggerType is IngestionTriggerType.Manual or IngestionTriggerType.Upload
            && (triggeredByUserId is null || triggeredByUserId == Guid.Empty))
        {
            return Error.Validation("DataIngestionJob.TriggeredByRequired", "A manual or uploaded job must record who started it.");
        }

        if (asOfDate > IngestionDates.TodayIst(startedAtUtc))
        {
            return Error.Validation("DataIngestionJob.FutureDate", "Cannot pull prices for a future date.");
        }

        return new DataIngestionJob(Guid.CreateVersion7(), priceSourceId, triggerType, triggeredByUserId, asOfDate, startedAtUtc);
    }

    /// <summary>The adapter itself could not run (source unreachable, or — until a real one is wired up — simply not configured).</summary>
    public void MarkAdapterFailed(string reason, DateTimeOffset completedAtUtc)
    {
        Status = IngestionJobStatus.Failed;
        FailureReason = Truncate(reason);
        CompletedAtUtc = completedAtUtc;
    }

    /// <summary>
    /// The adapter ran; each fetched record was persisted (new or changed), left unchanged (already stored with the
    /// same figures — a re-run or backfill of a day already pulled), or recorded as a <see cref="DataIngestionError"/>.
    /// </summary>
    public void Complete(int recordsFetched, int recordsPersisted, int recordsUnchanged, int recordsFailed, DateTimeOffset completedAtUtc)
    {
        RecordsFetched = recordsFetched;
        RecordsPersisted = recordsPersisted;
        RecordsUnchanged = recordsUnchanged;
        RecordsFailed = recordsFailed;
        Status = recordsFailed == 0
            ? IngestionJobStatus.Succeeded
            : recordsPersisted + recordsUnchanged > 0
                ? IngestionJobStatus.PartiallySucceeded
                : IngestionJobStatus.Failed;
        CompletedAtUtc = completedAtUtc;
    }

    private static string Truncate(string reason) =>
        reason.Length <= FailureReasonMaxLength ? reason : reason[..FailureReasonMaxLength];
}
