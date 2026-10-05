using Microsoft.Net.Http.Headers;

namespace MolBhav.Api.Setup;

internal static class CorsSetup
{
    public static IServiceCollection AddScopedCors(this IServiceCollection services, IConfiguration configuration, IHostEnvironment environment)
    {
        var settings = configuration.GetSection(CorsSettings.SectionName).Get<CorsSettings>() ?? new CorsSettings();

        if (settings.AllowAnyLocalhostPort && !environment.IsDevelopment())
        {
            throw new InvalidOperationException("Cors:AllowAnyLocalhostPort is only allowed in Development.");
        }

        foreach (var origin in settings.AllowedOrigins)
        {
            if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri) || (uri.Scheme != Uri.UriSchemeHttps && !uri.IsLoopback))
            {
                throw new InvalidOperationException($"Cors:AllowedOrigins entry '{origin}' must be an absolute https origin.");
            }
        }

        services.AddCors(options => options.AddPolicy(CorsSettings.PolicyName, policy =>
        {
            if (settings.AllowedOrigins.Length == 0 && !settings.AllowAnyLocalhostPort)
            {
                return;
            }

            var allowed = settings.AllowedOrigins.ToHashSet(StringComparer.OrdinalIgnoreCase);
            policy
                .SetIsOriginAllowed(origin => allowed.Contains(origin) || (settings.AllowAnyLocalhostPort && IsLocalhost(origin)))
                .WithMethods(HttpMethods.Get, HttpMethods.Post, HttpMethods.Put, HttpMethods.Patch, HttpMethods.Delete)
                // If-None-Match / ETag: conditional GETs from the web app (ConditionalGetMiddleware).
                .WithHeaders(HeaderNames.Authorization, HeaderNames.ContentType, HeaderNames.AcceptLanguage, HeaderNames.IfNoneMatch)
                .WithExposedHeaders(HeaderNames.RetryAfter, HeaderNames.ContentLanguage, HeaderNames.ContentDisposition, HeaderNames.ETag, "api-supported-versions")
                .SetPreflightMaxAge(TimeSpan.FromMinutes(10));
        }));

        return services;
    }

    private static bool IsLocalhost(string origin) =>
        Uri.TryCreate(origin, UriKind.Absolute, out var uri)
        && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps)
        && uri.IsLoopback;
}
