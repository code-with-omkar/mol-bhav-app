namespace MolBhav.Api.Setup;

/// <summary>IPs of the load balancer / reverse proxy allowed to set X-Forwarded-* (client IP drives rate limiting).</summary>
public sealed class ReverseProxySettings
{
    public const string SectionName = "ReverseProxy";

    public string[] KnownProxies { get; set; } = [];
}
