using System.Globalization;
using MolBhav.Application.Abstractions.Alerting;

namespace MolBhav.Infrastructure.Alerting;

/// <summary>Bound from the <c>Opportunities</c> section.</summary>
public sealed class OpportunityOptions : IOpportunitySettings
{
    public const string SectionName = "Opportunities";

    /// <summary>Runs the daily scan; when false only Admin "Find now" scans.</summary>
    public bool Enabled { get; set; } = true;

    /// <summary>IST time (HH:mm) after which the day's scan runs — after the morning price pulls.</summary>
    public string DailyRunTimeIst { get; set; } = "09:00";

    /// <summary>How often the worker checks whether today's scan is due.</summary>
    public int PollMinutes { get; set; } = 15;

    public decimal MinSavingsPercent { get; set; } = 10m;

    public int FreshnessDays { get; set; } = 7;

    public decimal ReferenceQuantity { get; set; } = 10m;

    public bool TryGetRunTime(out TimeOnly runAt) =>
        TimeOnly.TryParseExact(DailyRunTimeIst, "HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out runAt);
}
