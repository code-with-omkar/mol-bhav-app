namespace MolBhav.Api.Setup;

/// <summary>
/// Native mobile apps are not subject to CORS; this only governs browser clients (future admin portal).
/// Empty = no cross-origin browser access at all.
/// </summary>
public sealed class CorsSettings
{
    public const string SectionName = "Cors";
    public const string PolicyName = "MolBhavCors";

    public string[] AllowedOrigins { get; set; } = [];

    /// <summary>Development only: allow any <c>http(s)://localhost:*</c> origin (Flutter web picks a random port per run).</summary>
    public bool AllowAnyLocalhostPort { get; set; }
}
