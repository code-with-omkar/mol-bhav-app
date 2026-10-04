namespace MolBhav.Api.Setup;

/// <summary>Named policies for <c>[EnableRateLimiting(...)]</c>. Everything else falls under the global limiter.</summary>
public static class RateLimitPolicies
{
    /// <summary>Send-code endpoint (SMS cost, abuse).</summary>
    public const string Otp = "otp";

    /// <summary>Verify-code endpoint — separate budget from <see cref="Otp"/>.</summary>
    public const string OtpVerify = "otp-verify";

    /// <summary>Password login and registration, per IP — bounds credential stuffing across many numbers.</summary>
    public const string PasswordLogin = "password-login";

    /// <summary>Coupon validation, per user — bounds brute-forcing coupon codes.</summary>
    public const string CouponValidate = "coupon-validate";

    /// <summary>AdMob SSV callbacks, per IP — Google sends them from a few addresses, so they need their own, larger budget.</summary>
    public const string AdCallback = "ad-callback";

    /// <summary>Sponsored-card impression/click reports, per user — bounds how far one client can inflate a sponsor's counts.</summary>
    public const string PromotionEvents = "promotion-events";
}
