namespace MolBhav.Domain.Ingestion;

/// <summary>How often an <see cref="IngestionSchedule"/> fires. Stored as text.</summary>
public enum IngestionScheduleFrequency
{
    /// <summary>Once a day at <see cref="IngestionSchedule.TimeOfDay"/> (IST).</summary>
    Daily = 0,

    /// <summary>Once a week on <see cref="IngestionSchedule.DayOfWeek"/> at <see cref="IngestionSchedule.TimeOfDay"/> (IST).</summary>
    Weekly = 1,

    /// <summary>Every <see cref="IngestionSchedule.IntervalHours"/> hours, on slots anchored at <see cref="IngestionSchedule.TimeOfDay"/> (IST).</summary>
    EveryNHours = 2,
}
