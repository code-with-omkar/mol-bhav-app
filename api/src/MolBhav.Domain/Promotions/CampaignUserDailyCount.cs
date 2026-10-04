namespace MolBhav.Domain.Promotions;

/// <summary>
/// How much of one campaign's delivery one user has been credited with on one IST day. Counts are client-reported,
/// so this per-user ledger is what bounds them: no account can add more than <see cref="MaxImpressions"/> impressions
/// or <see cref="MaxClicks"/> clicks to a campaign per day (nor more clicks than impressions), which keeps one account
/// from inflating a sponsor's numbers or burning a rival's daily cap. Rows are upserted by the persistence layer;
/// only counts are kept, and old days can be purged once their campaign totals are final.
/// </summary>
public sealed class CampaignUserDailyCount
{
    /// <summary>A card shown on several screens and visits in a day; far above what one person really sees.</summary>
    public const int MaxImpressions = 20;

    public const int MaxClicks = 5;

    public CampaignUserDailyCount(Guid campaignId, Guid userId, DateOnly day, int impressions, int clicks)
    {
        CampaignId = campaignId;
        UserId = userId;
        Day = day;
        Impressions = impressions;
        Clicks = clicks;
    }

    public Guid CampaignId { get; private set; }

    public Guid UserId { get; private set; }

    public DateOnly Day { get; private set; }

    public int Impressions { get; private set; }

    public int Clicks { get; private set; }
}
