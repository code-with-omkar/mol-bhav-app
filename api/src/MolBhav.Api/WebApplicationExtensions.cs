using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using MolBhav.Api.Middleware;
using MolBhav.Api.Setup;
using Serilog;

namespace MolBhav.Api;

internal static class WebApplicationExtensions
{
    /// <summary>Middleware order is security-relevant — change with care.</summary>
    public static WebApplication UsePresentation(this WebApplication app)
    {
        app.UseForwardedHeaders();          // real client IP/scheme before anything reads them
        app.UseExceptionHandler();          // → GlobalExceptionHandler (RFC 7807)
        app.UseStatusCodePages();           // empty 401/403/404/405 → ProblemDetails

        if (!app.Environment.IsDevelopment())
        {
            app.UseHsts();
        }

        app.UseHttpsRedirection();
        app.UseMiddleware<SecurityHeadersMiddleware>();
        app.UseSerilogRequestLogging();
        app.UseApiResponseCompression();   // Brotli/gzip (not /auth) + ETag/304 for JSON GETs
        app.UseRequestLocalization();
        app.UseCors(CorsSettings.PolicyName);
        app.UseAuthentication();
        app.UseRateLimiter();               // after authentication: partitions by user id
        app.UseAuthorization();
        app.UseOutputCache();               // after auth: reference-data endpoints only (see ResponseCachingSetup)

        app.MapControllers();

        app.MapHealthChecks("/health/live", new HealthCheckOptions { Predicate = _ => false })
            .AllowAnonymous()
            .DisableRateLimiting();

        app.MapHealthChecks("/health/ready", new HealthCheckOptions
            {
                Predicate = check => check.Tags.Contains(Infrastructure.DependencyInjection.ReadinessTag),
            })
            .AllowAnonymous()
            .DisableRateLimiting();

        if (app.Environment.IsDevelopment())
        {
            // /openapi/v1.json — import into Postman. Not exposed outside Development.
            app.MapOpenApi().AllowAnonymous();
        }

        return app;
    }
}
