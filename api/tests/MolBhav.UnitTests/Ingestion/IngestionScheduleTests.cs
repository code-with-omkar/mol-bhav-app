using MolBhav.Domain.Ingestion;

namespace MolBhav.UnitTests.Ingestion;

public sealed class IngestionScheduleTests
{
    private static readonly Guid SourceId = Guid.CreateVersion7();

    /// <summary>IST wall-clock → UTC instant.</summary>
    private static DateTimeOffset Ist(int year, int month, int day, int hour, int minute) =>
        new DateTimeOffset(year, month, day, hour, minute, 0, IngestionSchedule.IstOffset).ToUniversalTime();

    private static IngestionSchedule Create(
        IngestionScheduleFrequency frequency,
        TimeOnly time,
        DateTimeOffset now,
        DayOfWeek? day = null,
        int? interval = null,
        bool enabled = true) =>
        IngestionSchedule.Create(SourceId, enabled, frequency, time, day, interval, now).Value;

    [Fact]
    public void Daily_BeforeTodaysTime_RunsToday()
    {
        var schedule = Create(IngestionScheduleFrequency.Daily, new TimeOnly(18, 0), Ist(2026, 10, 4, 9, 0));

        Assert.Equal(Ist(2026, 10, 4, 18, 0), schedule.NextRunAtUtc);
    }

    [Fact]
    public void Daily_AfterTodaysTime_RunsTomorrow()
    {
        var schedule = Create(IngestionScheduleFrequency.Daily, new TimeOnly(6, 0), Ist(2026, 10, 4, 9, 0));

        Assert.Equal(Ist(2026, 10, 5, 6, 0), schedule.NextRunAtUtc);
    }

    [Fact]
    public void Daily_UsesIstNotUtc_AcrossTheUtcDateBoundary()
    {
        // 02:00 IST on 5 Oct is 20:30 UTC on 4 Oct.
        var schedule = Create(IngestionScheduleFrequency.Daily, new TimeOnly(2, 0), Ist(2026, 10, 4, 23, 0));

        Assert.Equal(new DateTimeOffset(2026, 10, 4, 20, 30, 0, TimeSpan.Zero), schedule.NextRunAtUtc);
    }

    [Fact]
    public void Weekly_PicksTheNextMatchingDay()
    {
        // 4 Oct 2026 is a Sunday.
        var schedule = Create(IngestionScheduleFrequency.Weekly, new TimeOnly(7, 30), Ist(2026, 10, 4, 9, 0), DayOfWeek.Wednesday);

        Assert.Equal(Ist(2026, 10, 7, 7, 30), schedule.NextRunAtUtc);
    }

    [Fact]
    public void Weekly_SameDayButTimePassed_RunsNextWeek()
    {
        var schedule = Create(IngestionScheduleFrequency.Weekly, new TimeOnly(7, 30), Ist(2026, 10, 4, 9, 0), DayOfWeek.Sunday);

        Assert.Equal(Ist(2026, 10, 11, 7, 30), schedule.NextRunAtUtc);
    }

    [Fact]
    public void EveryNHours_LandsOnAnchoredSlots_IncludingBeforeTodaysAnchor()
    {
        // Anchor 06:00 every 6h → slots 00:00, 06:00, 12:00, 18:00.
        var early = Create(IngestionScheduleFrequency.EveryNHours, new TimeOnly(6, 0), Ist(2026, 10, 4, 1, 0), interval: 6);
        var midday = Create(IngestionScheduleFrequency.EveryNHours, new TimeOnly(6, 0), Ist(2026, 10, 4, 13, 15), interval: 6);

        Assert.Equal(Ist(2026, 10, 4, 6, 0), early.NextRunAtUtc);
        Assert.Equal(Ist(2026, 10, 4, 18, 0), midday.NextRunAtUtc);
    }

    [Fact]
    public void Disabled_HasNoNextRun_AndIsNeverDue()
    {
        var now = Ist(2026, 10, 4, 9, 0);
        var schedule = Create(IngestionScheduleFrequency.Daily, new TimeOnly(6, 0), now, enabled: false);

        Assert.Null(schedule.NextRunAtUtc);
        Assert.False(schedule.IsDue(now.AddDays(3)));
    }

    [Fact]
    public void MarkDispatched_WhenDue_RecordsRunAndAdvancesPastMissedSlots()
    {
        var schedule = Create(IngestionScheduleFrequency.Daily, new TimeOnly(6, 0), Ist(2026, 10, 4, 5, 0));
        var threeDaysLate = Ist(2026, 10, 7, 10, 0);

        var result = schedule.MarkDispatched(threeDaysLate);

        Assert.True(result.IsSuccess);
        Assert.Equal(threeDaysLate, schedule.LastRunAtUtc);
        Assert.Equal(Ist(2026, 10, 8, 6, 0), schedule.NextRunAtUtc);
    }

    [Fact]
    public void MarkDispatched_WhenNotDue_FailsAndChangesNothing()
    {
        var now = Ist(2026, 10, 4, 5, 0);
        var schedule = Create(IngestionScheduleFrequency.Daily, new TimeOnly(6, 0), now);

        var result = schedule.MarkDispatched(now);

        Assert.True(result.IsFailure);
        Assert.Null(schedule.LastRunAtUtc);
        Assert.Equal(Ist(2026, 10, 4, 6, 0), schedule.NextRunAtUtc);
    }

    [Theory]
    [InlineData(IngestionScheduleFrequency.Weekly, null, null, "IngestionSchedule.DayOfWeekRequired")]
    [InlineData(IngestionScheduleFrequency.EveryNHours, null, null, "IngestionSchedule.IntervalInvalid")]
    [InlineData(IngestionScheduleFrequency.EveryNHours, null, 5, "IngestionSchedule.IntervalInvalid")]
    public void Create_InvalidCombination_Fails(IngestionScheduleFrequency frequency, DayOfWeek? day, int? interval, string code)
    {
        var result = IngestionSchedule.Create(SourceId, true, frequency, new TimeOnly(6, 0), day, interval, Ist(2026, 10, 4, 9, 0));

        Assert.True(result.IsFailure);
        Assert.Equal(code, result.Error.Code);
    }

    [Fact]
    public void Configure_ClearsFieldsThatDoNotApplyToTheNewFrequency()
    {
        var now = Ist(2026, 10, 4, 9, 0);
        var schedule = Create(IngestionScheduleFrequency.Weekly, new TimeOnly(6, 0), now, DayOfWeek.Monday);

        schedule.Configure(true, IngestionScheduleFrequency.Daily, new TimeOnly(6, 0), DayOfWeek.Monday, 6, now);

        Assert.Null(schedule.DayOfWeek);
        Assert.Null(schedule.IntervalHours);
    }
}
