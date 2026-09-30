namespace MolBhav.Domain.Reporting;

/// <summary>What a <see cref="Report"/> summarizes. Kept as a closed set for MVP — the generator maps each value
/// to its own query/template; a genuinely ad-hoc/custom report is future scope.</summary>
public enum ReportType
{
    /// <summary>Daily prices for one product (optionally one mandi) over a date range. CSV, Pro only.</summary>
    PriceHistory = 0,
    Watchlist = 1,
    ProcurementSummary = 2,

    /// <summary>Watchlist prices and change, triggered alerts and sourcing opportunities over a date range. PDF.</summary>
    WeeklySummary = 3,
}
