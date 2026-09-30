namespace MolBhav.Domain.Ingestion;

/// <summary>Lifecycle of one <see cref="DataIngestionJob"/> run.</summary>
public enum IngestionJobStatus
{
    /// <summary>Created, not yet started (not currently reachable — jobs are created already <see cref="Running"/> — kept for a future queued-dispatch model).</summary>
    Pending = 0,

    Running = 1,

    /// <summary>Every fetched record was resolved and persisted with no errors.</summary>
    Succeeded = 2,

    /// <summary>Some records persisted, some failed resolution/validation — see the job's <see cref="DataIngestionError"/> rows.</summary>
    PartiallySucceeded = 3,

    /// <summary>The adapter itself failed (source unreachable/not configured) or every fetched record failed.</summary>
    Failed = 4,
}
