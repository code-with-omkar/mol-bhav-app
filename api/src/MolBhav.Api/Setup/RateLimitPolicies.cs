namespace MolBhav.Api.Setup;

/// <summary>Named policies for <c>[EnableRateLimiting(...)]</c>. Everything else falls under the global limiter.</summary>
public static class RateLimitPolicies
{
    /// <summary>Send-code endpoint (SMS cost, abuse).</summary>
    public const string Otp = "otp";

    /// <summary>Verify-code endpoint — separate budget from <see cref="Otp"/>.</summary>
    public const string OtpVerify = "otp-verify";
}
