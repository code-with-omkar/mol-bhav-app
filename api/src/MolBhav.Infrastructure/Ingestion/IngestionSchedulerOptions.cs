namespace MolBhav.Infrastructure.Ingestion;

public sealed class IngestionSchedulerOptions
{
    public const string SectionName = "IngestionScheduler";

    public bool Enabled { get; set; } = true;

    /// <summary>How often the scheduler runs one job per active <c>PriceSource</c> (BRD §27: "daily source data ingested" — default once a day).</summary>
    public int IntervalHours { get; set; } = 24;
}
