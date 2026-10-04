using MolBhav.Domain.Monetization;

namespace MolBhav.Infrastructure.Monetization;

/// <summary>Free-tier rules, bound from the <c>Monetization</c> section and validated at startup.</summary>
public sealed class MonetizationOptions
{
    public const string SectionName = "Monetization";

    public SlotAllowanceOptions Watchlist { get; set; } = new() { Included = 10, PerUnlock = 5, Maximum = 25, AdsPerUnlock = 1 };

    public SlotAllowanceOptions AlertRules { get; set; } = new() { Included = 5, PerUnlock = 2, Maximum = 11, AdsPerUnlock = 1 };

    public ReportAllowanceOptions PriceHistoryReports { get; set; } = new() { AdsPerUnlock = 2, UnlocksPerDay = 2, UnlockLifetimeHours = 24 };

    /// <summary>Unlocks granted without ads when none could be served, per user per day (IST).</summary>
    public int NoFillGrantsPerDay { get; set; } = 1;

    /// <summary>How long a "watch N ads" offer stays open once accepted.</summary>
    public int UnlockSessionLifetimeMinutes { get; set; } = 30;

    public FreeTierLimits ToLimits() => new(
        new SlotAllowance(Watchlist.Included, Watchlist.PerUnlock, Watchlist.Maximum, Watchlist.AdsPerUnlock),
        new SlotAllowance(AlertRules.Included, AlertRules.PerUnlock, AlertRules.Maximum, AlertRules.AdsPerUnlock),
        new ReportAllowance(
            PriceHistoryReports.AdsPerUnlock, PriceHistoryReports.UnlocksPerDay, TimeSpan.FromHours(PriceHistoryReports.UnlockLifetimeHours)),
        NoFillGrantsPerDay,
        TimeSpan.FromMinutes(UnlockSessionLifetimeMinutes));
}

public sealed class SlotAllowanceOptions
{
    public int Included { get; set; }

    public int PerUnlock { get; set; }

    public int Maximum { get; set; }

    public int AdsPerUnlock { get; set; }
}

public sealed class ReportAllowanceOptions
{
    public int AdsPerUnlock { get; set; }

    public int UnlocksPerDay { get; set; }

    public int UnlockLifetimeHours { get; set; }
}
