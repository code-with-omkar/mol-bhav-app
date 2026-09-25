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
}
