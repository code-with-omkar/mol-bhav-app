namespace MolBhav.Domain.Promotions;

/// <summary>
/// Delivery counts for one campaign on one IST day — what a sponsor is shown and billed on. Only aggregate counts
/// are kept (no per-user event log), which keeps personal-data exposure low. Rows are upserted atomically by the
/// persistence layer; this type exists for the schema and for reading.
/// </summary>
public sealed class CampaignDailyStat
{
    public CampaignDailyStat(Guid campaignId, DateOnly day, int impressions, int clicks)
    {
        CampaignId = campaignId;
        Day = day;
        Impressions = impressions;
        Clicks = clicks;
    }

    public Guid CampaignId { get; private set; }

    public DateOnly Day { get; private set; }

    public int Impressions { get; private set; }

    public int Clicks { get; private set; }
}
