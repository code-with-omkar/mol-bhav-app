namespace MolBhav.Infrastructure.Notifications;

/// <summary>Bound from the <c>Push:Fcm</c> section. The service account JSON must come from user-secrets (dev) or an
/// environment variable / Key Vault (prod) — never from appsettings.json.</summary>
public sealed class FcmCredentialOptions
{
    public const string SectionName = "Push:Fcm";

    /// <summary>The full service-account key JSON. Required in non-Development environments.</summary>
    public string ServiceAccountJson { get; init; } = string.Empty;
}
