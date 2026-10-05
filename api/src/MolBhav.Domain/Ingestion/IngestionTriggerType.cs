namespace MolBhav.Domain.Ingestion;

/// <summary>What started a <see cref="DataIngestionJob"/> (BRD §9/§18 — background workers, plus an admin-triggered path).</summary>
public enum IngestionTriggerType
{
    /// <summary>An admin triggered the run for one source on demand.</summary>
    Manual = 0,

    /// <summary>The scheduler background service triggered the run on its configured interval.</summary>
    Scheduled = 1,

    /// <summary>An admin uploaded a file (e.g. an Agmarknet CSV export) — the fallback when the source's API is down.</summary>
    Upload = 2,
}
