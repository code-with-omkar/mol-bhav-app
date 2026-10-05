using System.Security.Cryptography;
using Microsoft.Net.Http.Headers;

namespace MolBhav.Api.Middleware;

/// <summary>
/// ETag + <c>If-None-Match</c> for JSON GETs under <c>/api</c>: the body is hashed and, when the client already holds
/// that exact body, the API answers <c>304 Not Modified</c> with no payload — the app reuses its cached copy. Saves the
/// download (not the query) on every unchanged list: catalog, mandis, latest prices, watchlist, alerts…
/// <list type="bullet">
/// <item>Only <c>200 application/json</c> responses up to <see cref="MaxBufferedBytes"/>; downloads are skipped.</item>
/// <item>Bodies are deterministic (the <c>ApiResponse</c> envelope has no timestamps), so equal data ⇒ equal tag.</item>
/// <item>Per-user responses are safe: the tag is computed per response, and <c>Cache-Control: private, no-cache</c>
/// (set unless an endpoint chose its own) keeps shared proxies from storing them and makes clients revalidate.</item>
/// </list>
/// Runs inside response compression, so the tag describes the uncompressed JSON whatever encoding is negotiated.
/// </summary>
internal sealed class ConditionalGetMiddleware(RequestDelegate next)
{
    /// <summary>Larger JSON is streamed through untouched rather than held in memory.</summary>
    public const int MaxBufferedBytes = 2 * 1024 * 1024;

    public async Task InvokeAsync(HttpContext context)
    {
        if (!Applies(context.Request))
        {
            await next(context);
            return;
        }

        var original = context.Response.Body;
        await using var buffer = new MemoryStream();
        context.Response.Body = buffer;

        try
        {
            await next(context);
        }
        finally
        {
            context.Response.Body = original;
        }

        var response = context.Response;
        if (response.StatusCode != StatusCodes.Status200OK
            || buffer.Length is 0 or > MaxBufferedBytes
            || response.ContentType?.StartsWith("application/json", StringComparison.OrdinalIgnoreCase) != true
            || response.Headers.ContainsKey(HeaderNames.ETag))
        {
            await CopyAsync(buffer, original, context.RequestAborted);
            return;
        }

        var etag = ComputeETag(buffer);
        response.Headers.ETag = etag;
        if (!response.Headers.ContainsKey(HeaderNames.CacheControl))
        {
            response.Headers.CacheControl = "private, no-cache";
        }

        if (Matches(context.Request, etag))
        {
            response.StatusCode = StatusCodes.Status304NotModified;
            response.ContentLength = null;
            response.Headers.Remove(HeaderNames.ContentType);
            return;
        }

        response.ContentLength = buffer.Length;
        await CopyAsync(buffer, original, context.RequestAborted);
    }

    private static bool Applies(HttpRequest request) =>
        HttpMethods.IsGet(request.Method)
        && request.Path.StartsWithSegments("/api", StringComparison.OrdinalIgnoreCase)
        && !request.Path.Value!.EndsWith("/download", StringComparison.OrdinalIgnoreCase);

    /// <summary>Weak tag: equal JSON, not byte-for-byte equal encodings (compression may differ).</summary>
    internal static string ComputeETag(MemoryStream body)
    {
        var hash = SHA256.HashData(body.GetBuffer().AsSpan(0, (int)body.Length));
        return $"W/\"{Convert.ToBase64String(hash, 0, 16).TrimEnd('=').Replace('+', '-').Replace('/', '_')}\"";
    }

    internal static bool Matches(HttpRequest request, string etag)
    {
        foreach (var value in request.Headers.IfNoneMatch)
        {
            if (value is null)
            {
                continue;
            }

            foreach (var candidate in value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            {
                // Compare weakly: the client may echo the tag with or without the W/ prefix.
                if (candidate == "*" || string.Equals(Strip(candidate), Strip(etag), StringComparison.Ordinal))
                {
                    return true;
                }
            }
        }

        return false;
    }

    private static string Strip(string tag) => tag.StartsWith("W/", StringComparison.Ordinal) ? tag[2..] : tag;

    private static async Task CopyAsync(MemoryStream buffer, Stream destination, CancellationToken cancellationToken)
    {
        if (buffer.Length == 0)
        {
            return;
        }

        buffer.Position = 0;
        await buffer.CopyToAsync(destination, cancellationToken);
    }
}
