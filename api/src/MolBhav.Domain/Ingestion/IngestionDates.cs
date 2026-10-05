namespace MolBhav.Domain.Ingestion;

/// <summary>
/// Which publication date a pull targets. Mandi prices are published per Indian calendar day, so "today" is the IST
/// date, not the UTC one — at 02:00 IST it is still yesterday in UTC.
/// </summary>
public static class IngestionDates
{
    /// <summary>Agmarknet usually completes a day's arrivals the next day, so pulls default to yesterday.</summary>
    public const int DefaultDataLagDays = 1;

    /// <summary>Upper bound on one backfill request: a month of daily runs.</summary>
    public const int MaxBackfillDays = 31;

    public static DateOnly TodayIst(DateTimeOffset nowUtc) =>
        DateOnly.FromDateTime(nowUtc.ToOffset(IngestionSchedule.IstOffset).DateTime);

    /// <summary>The date a run pulls when none is given: today in IST minus <paramref name="lagDays"/>.</summary>
    public static DateOnly DefaultAsOf(DateTimeOffset nowUtc, int lagDays = DefaultDataLagDays) =>
        TodayIst(nowUtc).AddDays(-Math.Max(0, lagDays));
}
