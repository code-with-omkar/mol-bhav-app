namespace MolBhav.Api.Setup;

public sealed class RateLimitingSettings
{
    public const string SectionName = "RateLimiting";

    public int AuthenticatedPermitLimit { get; set; } = 120;

    public int AnonymousPermitLimit { get; set; } = 30;

    public int WindowSeconds { get; set; } = 60;

    /// <summary>OTP send/verify is the most abusable endpoint (SMS cost, brute force) — much tighter.</summary>
    public int OtpPermitLimit { get; set; } = 5;

    public int OtpWindowSeconds { get; set; } = 600;
}
