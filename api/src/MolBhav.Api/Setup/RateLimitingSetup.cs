using System.Globalization;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Application.Abstractions.Authentication;

namespace MolBhav.Api.Setup;

internal static class RateLimitingSetup
{
    public static IServiceCollection AddApiRateLimiting(this IServiceCollection services, IConfiguration configuration)
    {
        var settings = configuration.GetSection(RateLimitingSettings.SectionName).Get<RateLimitingSettings>() ?? new RateLimitingSettings();
        var window = TimeSpan.FromSeconds(settings.WindowSeconds);

        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

            // Partition by user when authenticated (fair across shared NAT/mobile-carrier IPs), otherwise by client IP.
            options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
            {
                var userId = context.User.FindFirst(MolBhavClaimTypes.Subject)?.Value;

                return userId is not null
                    ? RateLimitPartition.GetFixedWindowLimiter($"user:{userId}", _ => FixedWindow(settings.AuthenticatedPermitLimit, window))
                    : RateLimitPartition.GetFixedWindowLimiter($"ip:{ClientIp(context)}", _ => FixedWindow(settings.AnonymousPermitLimit, window));
            });

            options.AddPolicy(RateLimitPolicies.Otp, context =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"otp:{ClientIp(context)}",
                    _ => FixedWindow(settings.OtpPermitLimit, TimeSpan.FromSeconds(settings.OtpWindowSeconds))));

            options.AddPolicy(RateLimitPolicies.OtpVerify, context =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"otp-verify:{ClientIp(context)}",
                    _ => FixedWindow(settings.OtpVerifyPermitLimit, TimeSpan.FromSeconds(settings.OtpWindowSeconds))));

            options.AddPolicy(RateLimitPolicies.CouponValidate, context =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"coupon:{context.User.FindFirst(MolBhavClaimTypes.Subject)?.Value ?? ClientIp(context)}",
                    _ => FixedWindow(settings.CouponValidatePermitLimit, window)));

            options.OnRejected =async (context, cancellationToken) =>
            {
                if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
                {
                    context.HttpContext.Response.Headers.RetryAfter =
                        ((int)Math.Ceiling(retryAfter.TotalSeconds)).ToString(CultureInfo.InvariantCulture);
                }

                var problemDetailsService = context.HttpContext.RequestServices.GetRequiredService<IProblemDetailsService>();
                await problemDetailsService.WriteAsync(new ProblemDetailsContext
                {
                    HttpContext = context.HttpContext,
                    ProblemDetails = new ProblemDetails
                    {
                        Status = StatusCodes.Status429TooManyRequests,
                        Title = "Too many requests.",
                        Detail = "Request limit exceeded. Retry after the period indicated by the Retry-After header.",
                    },
                });
            };
        });

        return services;
    }

    private static FixedWindowRateLimiterOptions FixedWindow(int permitLimit, TimeSpan window) => new()
    {
        PermitLimit = permitLimit,
        Window = window,
        QueueLimit = 0,
        AutoReplenishment = true,
    };

    /// <summary>Correct behind a proxy only when ReverseProxy:KnownProxies is configured (forwarded headers run first).</summary>
    private static string ClientIp(HttpContext context) =>
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
}
