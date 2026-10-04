using MolBhav.Domain.Ingestion;

namespace MolBhav.Api.Contracts.Ingestion;

/// <summary>A source's automatic pull schedule. Times are India Standard Time.</summary>
/// <param name="IsEnabled">Off keeps the settings but stops automatic runs.</param>
/// <param name="Frequency"><c>Daily</c>, <c>Weekly</c> or <c>EveryNHours</c>.</param>
/// <param name="TimeOfDay">24-hour <c>HH:mm</c> IST — the run time, or the first slot of the day for <c>EveryNHours</c>.</param>
/// <param name="DayOfWeek">Required for <c>Weekly</c>, e.g. <c>Monday</c>.</param>
/// <param name="IntervalHours">Required for <c>EveryNHours</c>: 1, 2, 3, 4, 6, 8 or 12.</param>
public sealed record UpdateIngestionScheduleRequest(
    bool? IsEnabled,
    IngestionScheduleFrequency? Frequency,
    string? TimeOfDay,
    DayOfWeek? DayOfWeek,
    int? IntervalHours);
