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
}
