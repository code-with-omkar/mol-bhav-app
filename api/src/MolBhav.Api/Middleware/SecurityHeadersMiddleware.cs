namespace MolBhav.Api.Middleware;

/// <summary>OWASP secure-headers baseline for a JSON-only API (no HTML is ever served, so CSP is fully locked down).</summary>
internal sealed class SecurityHeadersMiddleware(RequestDelegate next)
{
    public Task InvokeAsync(HttpContext context)
    {
        var headers = context.Response.Headers;

        headers.XContentTypeOptions = "nosniff";
        headers.XFrameOptions = "DENY";
        headers.ContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'";
        headers["Referrer-Policy"] = "no-referrer";
        headers["Permissions-Policy"] = "accelerometer=(), camera=(), geolocation=(), microphone=(), payment=(), usb=()";
        headers["Cross-Origin-Opener-Policy"] = "same-origin";

        return next(context);
    }
}
