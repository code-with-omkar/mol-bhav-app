namespace MolBhav.Api.Setup;

/// <summary>Named policies for <c>[EnableRateLimiting(...)]</c>. Everything else falls under the global limiter.</summary>
public static class RateLimitPolicies
{
    public const string Otp = "otp";
}
