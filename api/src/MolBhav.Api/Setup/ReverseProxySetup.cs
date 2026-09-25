using System.Net;
using Microsoft.AspNetCore.HttpOverrides;

namespace MolBhav.Api.Setup;

internal static class ReverseProxySetup
{
    public static IServiceCollection AddReverseProxySupport(this IServiceCollection services, IConfiguration configuration)
    {
        var settings = configuration.GetSection(ReverseProxySettings.SectionName).Get<ReverseProxySettings>() ?? new ReverseProxySettings();

        var proxies = settings.KnownProxies
            .Select(value => IPAddress.TryParse(value, out var address)
                ? address
                : throw new InvalidOperationException($"ReverseProxy:KnownProxies entry '{value}' is not a valid IP address."))
            .ToArray();

        services.Configure<ForwardedHeadersOptions>(options =>
        {
            options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
            options.ForwardLimit = 1;

            foreach (var proxy in proxies)
            {
                options.KnownProxies.Add(proxy);
            }
        });

        return services;
    }
}
