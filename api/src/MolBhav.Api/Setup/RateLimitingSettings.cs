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

    /// <summary>
    /// Verify gets its own per-IP budget so a few typos do not exhaust the send budget. Per-code brute force is already
    /// capped by the domain (5 attempts per challenge); this bounds guessing across many phone numbers from one client.
    /// </summary>
    public int OtpVerifyPermitLimit { get; set; } = 15;

    /// <summary>Coupon checks per user per <see cref="WindowSeconds"/>; the checkout screen debounces, so real users need few.</summary>
    public int CouponValidatePermitLimit { get; set; } = 10;
}
