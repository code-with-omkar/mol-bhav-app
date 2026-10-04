namespace MolBhav.Infrastructure.Monetization;

/// <summary>Rewarded-ad server-side verification (SSV), bound from the <c>AdMob</c> section.</summary>
public sealed class AdMobOptions
{
    public const string SectionName = "AdMob";

    /// <summary>Google's published ECDSA public keys for SSV signatures.</summary>
    public Uri VerifierKeysUrl { get; set; } = new("https://www.gstatic.com/admob/reward/verifier-keys.json");

    /// <summary>How long fetched keys are trusted before a refresh; Google rotates them rarely.</summary>
    public int KeyCacheHours { get; set; } = 24;

    /// <summary>Minimum gap between refreshes forced by an unknown key id, so forged ids can't hammer Google.</summary>
    public int MinRefreshIntervalSeconds { get; set; } = 60;
}
