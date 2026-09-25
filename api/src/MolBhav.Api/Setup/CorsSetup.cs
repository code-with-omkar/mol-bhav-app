using Microsoft.Net.Http.Headers;

namespace MolBhav.Api.Setup;

internal static class CorsSetup
{
    public static IServiceCollection AddScopedCors(this IServiceCollection services, IConfiguration configuration)
    {
        var settings = configuration.GetSection(CorsSettings.SectionName).Get<CorsSettings>() ?? new CorsSettings();

        foreach (var origin in settings.AllowedOrigins)
        {
            if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri) || (uri.Scheme != Uri.UriSchemeHttps && !uri.IsLoopback))
            {
                throw new InvalidOperationException($"Cors:AllowedOrigins entry '{origin}' must be an absolute https origin.");
            }
        }

        services.AddCors(options => options.AddPolicy(CorsSettings.PolicyName, policy =>
        {
            if (settings.AllowedOrigins.Length == 0)
            {
                return;
            }

            policy
                .WithOrigins(settings.AllowedOrigins)
                .WithMethods(HttpMethods.Get, HttpMethods.Post, HttpMethods.Put, HttpMethods.Patch, HttpMethods.Delete)
                .WithHeaders(HeaderNames.Authorization, HeaderNames.ContentType, HeaderNames.AcceptLanguage)
                .WithExposedHeaders(HeaderNames.RetryAfter, HeaderNames.ContentLanguage, "api-supported-versions")
                .SetPreflightMaxAge(TimeSpan.FromMinutes(10));
        }));

        return services;
    }
}
