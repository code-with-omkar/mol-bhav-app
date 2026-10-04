namespace MolBhav.Infrastructure.Ingestion;

public sealed class IngestionSchedulerOptions
{
    public const string SectionName = "IngestionScheduler";

    /// <summary>Master switch. Off: no source is pulled automatically (manual "Run now" still works).</summary>
    public bool Enabled { get; set; } = true;

    /// <summary>How often the scheduler checks for due schedules. Schedules are minute-granular, so 60 s is enough.</summary>
    public int PollIntervalSeconds { get; set; } = 60;

    /// <summary>Upper bound on sources started in one check, so a long outage cannot start a burst of runs at once.</summary>
    public int MaxRunsPerTick { get; set; } = 10;
}
