using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Promotions;

public static class PromotionErrors
{
    public static readonly Error AdvertiserNotFound = Error.NotFound("Advertiser.NotFound", "Advertiser not found.");

    public static readonly Error CampaignNotFound = Error.NotFound("Campaign.NotFound", "Campaign not found.");

    public static readonly Error UnknownCategory = Error.Validation("Campaign.UnknownCategory", "A targeted category does not exist.");

    public static readonly Error UnknownState = Error.Validation("Campaign.UnknownState", "A targeted state does not exist.");
}
