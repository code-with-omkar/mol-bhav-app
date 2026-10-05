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

    /// <summary>
    /// Scheduled runs pull the IST date this many days back. Agmarknet usually completes a day's arrivals the next day,
    /// so 1 (yesterday) is the default; 0 pulls today's partial data.
    /// </summary>
    public int DataLagDays { get; set; } = Domain.Ingestion.IngestionDates.DefaultDataLagDays;

    /// <summary>Pause between dates in a backfill, to stay polite to the public API.</summary>
    public int BackfillDelaySeconds { get; set; } = 2;
}
