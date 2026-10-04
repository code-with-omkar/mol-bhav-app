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

    /// <summary>
    /// Password login/register attempts per IP per <see cref="OtpWindowSeconds"/>. Per-account guessing is already capped
    /// by the domain lockout (5 wrong passwords → 15 minutes); this bounds guessing across many numbers from one client.
    /// </summary>
    public int PasswordLoginPermitLimit { get; set; } = 20;

    /// <summary>Coupon checks per user per <see cref="WindowSeconds"/>; the checkout screen debounces, so real users need few.</summary>
    public int CouponValidatePermitLimit { get; set; } = 10;

    /// <summary>
    /// AdMob SSV callbacks per IP per <see cref="WindowSeconds"/>. Google's callback servers share few IPs, so this is
    /// sized for peak rewarded views, while still bounding signature-check work from a forger.
    /// </summary>
    public int AdCallbackPermitLimit { get; set; } = 600;

    /// <summary>
    /// Sponsored-card event batches per user per <see cref="WindowSeconds"/>. The app flushes at most every 30 seconds
    /// (or on 20 queued events / backgrounding), so a handful is plenty; each batch is also capped per campaign.
    /// </summary>
    public int PromotionEventsPermitLimit { get; set; } = 6;
}
