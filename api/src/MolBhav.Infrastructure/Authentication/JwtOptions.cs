namespace MolBhav.Infrastructure.Authentication;

/// <summary>
/// Bound from the <c>Jwt</c> section. <see cref="SigningKey"/> must come from user-secrets / environment / Key Vault —
/// never from appsettings.json. Validated at startup.
/// </summary>
public sealed class JwtOptions
{
    public const string SectionName = "Jwt";
    public const int MinimumSigningKeyBytes = 32;

    public string Issuer { get; set; } = string.Empty;

    public string Audience { get; set; } = string.Empty;

    public string SigningKey { get; set; } = string.Empty;

    public int AccessTokenLifetimeMinutes { get; set; } = 15;

    public int RefreshTokenLifetimeDays { get; set; } = 30;

    public int ClockSkewSeconds { get; set; } = 30;
}
