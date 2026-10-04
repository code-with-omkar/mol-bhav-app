namespace MolBhav.Domain.Monetization;

public enum FeatureGrantSource
{
    /// <summary>Earned by rewarded-ad views confirmed through AdMob's signed server-side callback.</summary>
    RewardedAds = 0,

    /// <summary>Issued because no ad could be served (no fill); capped per day.</summary>
    NoFill = 1,

    /// <summary>Issued by an administrator (support goodwill, testing).</summary>
    Admin = 2,
}
