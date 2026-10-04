using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Ingestion;

/// <summary>
/// When the scheduler pulls a <c>PriceSource</c> automatically — at most one schedule per source, configured by an admin
/// (BRD §9/§22). Times are wall-clock India Standard Time (fixed UTC+05:30, no DST), which is how mandi data is
/// published and how admins think about it; the next run is materialised as <see cref="NextRunAtUtc"/> so the scheduler
/// only needs an indexed "due now" query. A disabled schedule has no next run.
/// </summary>
public sealed class IngestionSchedule : AggregateRoot<Guid>, IAuditableEntity
{
    /// <summary>Divisors of 24, so "every N hours" lands on the same clock slots every day.</summary>
    public static readonly IReadOnlySet<int> AllowedIntervalHours = new HashSet<int> { 1, 2, 3, 4, 6, 8, 12 };

    /// <summary>India Standard Time. Fixed offset on purpose: no DST in India and no OS time-zone database dependency.</summary>
    public static readonly TimeSpan IstOffset = new(5, 30, 0);

    private IngestionSchedule(Guid id, Guid priceSourceId)
        : base(id)
    {
        PriceSourceId = priceSourceId;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private IngestionSchedule()
    {
    }

    public Guid PriceSourceId { get; private set; }

    public bool IsEnabled { get; private set; }

    public IngestionScheduleFrequency Frequency { get; private set; }

    /// <summary>IST wall-clock time: the run time for Daily/Weekly, the first slot of the day for EveryNHours.</summary>
    public TimeOnly TimeOfDay { get; private set; }

    /// <summary>Set only for <see cref="IngestionScheduleFrequency.Weekly"/>.</summary>
    public DayOfWeek? DayOfWeek { get; private set; }

    /// <summary>Set only for <see cref="IngestionScheduleFrequency.EveryNHours"/>; one of <see cref="AllowedIntervalHours"/>.</summary>
    public int? IntervalHours { get; private set; }

    /// <summary>Null exactly when <see cref="IsEnabled"/> is false.</summary>
    public DateTimeOffset? NextRunAtUtc { get; private set; }

    /// <summary>When the scheduler last dispatched a run for this schedule (manual runs do not count).</summary>
    public DateTimeOffset? LastRunAtUtc { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<IngestionSchedule> Create(
        Guid priceSourceId,
        bool isEnabled,
        IngestionScheduleFrequency frequency,
        TimeOnly timeOfDay,
        DayOfWeek? dayOfWeek,
        int? intervalHours,
        DateTimeOffset nowUtc)
    {
        if (priceSourceId == Guid.Empty)
        {
            return Error.Validation("IngestionSchedule.PriceSourceRequired", "Price source is required.");
        }

        var schedule = new IngestionSchedule(Guid.CreateVersion7(), priceSourceId);
        var configured = schedule.Configure(isEnabled, frequency, timeOfDay, dayOfWeek, intervalHours, nowUtc);
        return configured.IsFailure ? Result.Failure<IngestionSchedule>(configured.Error) : schedule;
    }

    /// <summary>Replaces the whole schedule and recomputes the next run from <paramref name="nowUtc"/>.</summary>
    public Result Configure(
        bool isEnabled,
        IngestionScheduleFrequency frequency,
        TimeOnly timeOfDay,
        DayOfWeek? dayOfWeek,
        int? intervalHours,
        DateTimeOffset nowUtc)
    {
        if (!Enum.IsDefined(frequency))
        {
            return Error.Validation("IngestionSchedule.FrequencyInvalid", "Unknown frequency.");
        }

        if (frequency == IngestionScheduleFrequency.Weekly && dayOfWeek is null)
        {
            return Error.Validation("IngestionSchedule.DayOfWeekRequired", "A weekly schedule needs a day of the week.");
        }

        if (frequency == IngestionScheduleFrequency.EveryNHours
            && (intervalHours is null || !AllowedIntervalHours.Contains(intervalHours.Value)))
        {
            return Error.Validation(
                "IngestionSchedule.IntervalInvalid",
                $"Interval must be one of {string.Join(", ", AllowedIntervalHours.Order())} hours.");
        }

        IsEnabled = isEnabled;
        Frequency = frequency;
        TimeOfDay = new TimeOnly(timeOfDay.Hour, timeOfDay.Minute);
        DayOfWeek = frequency == IngestionScheduleFrequency.Weekly ? dayOfWeek : null;
        IntervalHours = frequency == IngestionScheduleFrequency.EveryNHours ? intervalHours : null;
        NextRunAtUtc = isEnabled ? NextOccurrenceAfter(nowUtc) : null;
        return Result.Success();
    }

    /// <summary>True when the scheduler should run this source now.</summary>
    public bool IsDue(DateTimeOffset nowUtc) => IsEnabled && NextRunAtUtc is { } next && next <= nowUtc;

    /// <summary>
    /// The scheduler claimed this slot: records the run and moves to the next slot strictly after <paramref name="nowUtc"/>,
    /// so missed slots (API was down) collapse into one catch-up run instead of a burst.
    /// </summary>
    public Result MarkDispatched(DateTimeOffset nowUtc)
    {
        if (!IsDue(nowUtc))
        {
            return Error.Conflict("IngestionSchedule.NotDue", "This schedule is not due.");
        }

        LastRunAtUtc = nowUtc;
        NextRunAtUtc = NextOccurrenceAfter(nowUtc);
        return Result.Success();
    }

    /// <summary>First slot strictly after <paramref name="afterUtc"/>, returned in UTC.</summary>
    public DateTimeOffset NextOccurrenceAfter(DateTimeOffset afterUtc)
    {
        var afterIst = afterUtc.ToOffset(IstOffset);
        var todayAnchor = new DateTimeOffset(DateOnly.FromDateTime(afterIst.DateTime).ToDateTime(TimeOfDay), IstOffset);

        DateTimeOffset next;
        switch (Frequency)
        {
            case IngestionScheduleFrequency.Daily:
                next = todayAnchor > afterIst ? todayAnchor : todayAnchor.AddDays(1);
                break;

            case IngestionScheduleFrequency.Weekly:
                var days = ((int)DayOfWeek!.Value - (int)todayAnchor.DayOfWeek + 7) % 7;
                next = todayAnchor.AddDays(days);
                if (next <= afterIst)
                {
                    next = next.AddDays(7);
                }

                break;

            case IngestionScheduleFrequency.EveryNHours:
                // Slots are anchor + k·N hours; start from the previous day's anchor so early-morning times before
                // today's anchor still find yesterday's later slots (e.g. 06:00 every 6h → 00:00 is a slot).
                var step = TimeSpan.FromHours(IntervalHours!.Value);
                next = todayAnchor.AddDays(-1);
                while (next <= afterIst)
                {
                    next = next.Add(step);
                }

                break;

            default:
                throw new InvalidOperationException($"Unhandled frequency {Frequency}.");
        }

        return next.ToUniversalTime();
    }
}
