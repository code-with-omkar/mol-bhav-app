using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Ingestion.Admin.UpdateIngestionSchedule;

/// <summary>
/// Creates or replaces a source's schedule. <paramref name="TimeOfDay"/> is IST <c>HH:mm</c>;
/// <paramref name="DayOfWeek"/> is required for Weekly, <paramref name="IntervalHours"/> for EveryNHours.
/// </summary>
public sealed record UpdateIngestionScheduleCommand(
    Guid PriceSourceId,
    bool? IsEnabled,
    IngestionScheduleFrequency? Frequency,
    string? TimeOfDay,
    DayOfWeek? DayOfWeek,
    int? IntervalHours) : ICommand;
