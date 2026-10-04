namespace MolBhav.Application.Features.Monetization;

/// <summary>Daily caps reset at midnight IST — users are in India (one zone, no DST).</summary>
internal static class IndiaDay
{
    private static readonly TimeSpan Offset = TimeSpan.FromHours(5.5);

    /// <summary>The UTC instant today (IST) began.</summary>
    public static DateTimeOffset StartUtc(DateTimeOffset nowUtc)
    {
        var local = nowUtc.ToOffset(Offset);
        return new DateTimeOffset(local.Date, Offset).ToUniversalTime();
    }

    /// <summary>Today's date in IST.</summary>
    public static DateOnly Today(DateTimeOffset nowUtc) => DateOnly.FromDateTime(nowUtc.ToOffset(Offset).DateTime);
}
