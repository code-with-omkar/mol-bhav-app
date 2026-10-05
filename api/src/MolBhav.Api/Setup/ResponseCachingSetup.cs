using System.IO.Compression;
using Microsoft.AspNetCore.OutputCaching;
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.Extensions.Primitives;
using Microsoft.Net.Http.Headers;
using MolBhav.Api.Middleware;

namespace MolBhav.Api.Setup;

/// <summary>
/// Transport-level speed-ups for the mobile app:
/// <list type="bullet">
/// <item><b>Compression</b> (Brotli, then gzip) for JSON — price lists shrink ~70–85% on 3G/4G. Not applied to
/// <c>/auth</c>, whose bodies carry tokens next to request-influenced fields (BREACH).</item>
/// <item><b>ETag / 304</b> — <see cref="ConditionalGetMiddleware"/>.</item>
/// <item><b>Server output cache</b> for user-independent reference data (catalog, market master data, plans), varied by
/// query and <c>Accept-Language</c>, evicted by <see cref="EvictReferenceDataCacheAttribute"/> on admin writes.</item>
/// </list>
/// </summary>
internal static class ResponseCachingSetup
{
    public const string ReferenceDataPolicy = "reference-data";
    public const string ReferenceDataTag = "reference-data";

    /// <summary>Upper bound on staleness if an edit bypasses the admin API (e.g. a SQL fix).</summary>
    public static readonly TimeSpan ReferenceDataLifetime = TimeSpan.FromMinutes(10);

    public static IServiceCollection AddApiResponseCaching(this IServiceCollection services)
    {
        services.AddResponseCompression(options =>
        {
            options.EnableForHttps = true;
            options.Providers.Add<BrotliCompressionProvider>();
            options.Providers.Add<GzipCompressionProvider>();
            options.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(["application/problem+json"]);
        });
        services.Configure<BrotliCompressionProviderOptions>(o => o.Level = CompressionLevel.Fastest);
        services.Configure<GzipCompressionProviderOptions>(o => o.Level = CompressionLevel.Fastest);

        services.AddOutputCache(options =>
            options.AddPolicy(ReferenceDataPolicy, builder => builder.AddPolicy<ReferenceDataOutputCachePolicy>(), excludeDefaultPolicy: true));

        return services;
    }

    /// <summary>Compression (outside /auth), then conditional GET — order matters: the ETag is of uncompressed JSON.</summary>
    public static IApplicationBuilder UseApiResponseCompression(this IApplicationBuilder app)
    {
        app.UseWhen(
            context => !context.Request.Path.StartsWithSegments("/api/v1/auth", StringComparison.OrdinalIgnoreCase),
            branch => branch.UseResponseCompression());
        app.UseMiddleware<ConditionalGetMiddleware>();
        return app;
    }
}

/// <summary>
/// Caches GET 200s of endpoints marked <c>[OutputCache(PolicyName = ReferenceDataPolicy)]</c>. Unlike the default
/// policy it also caches requests that carry an <c>Authorization</c> header — the app always sends one — which is safe
/// only because these endpoints return the same data to every caller (only the language varies).
/// </summary>
internal sealed class ReferenceDataOutputCachePolicy : IOutputCachePolicy
{
    public ValueTask CacheRequestAsync(OutputCacheContext context, CancellationToken cancellation)
    {
        var isGet = HttpMethods.IsGet(context.HttpContext.Request.Method) || HttpMethods.IsHead(context.HttpContext.Request.Method);
        context.EnableOutputCaching = true;
        context.AllowCacheLookup = isGet;
        context.AllowCacheStorage = isGet;
        context.AllowLocking = true;
        context.ResponseExpirationTimeSpan = ResponseCachingSetup.ReferenceDataLifetime;
        context.CacheVaryByRules.QueryKeys = "*";
        context.CacheVaryByRules.HeaderNames = new StringValues(HeaderNames.AcceptLanguage);
        context.Tags.Add(ResponseCachingSetup.ReferenceDataTag);
        return ValueTask.CompletedTask;
    }

    public ValueTask ServeFromCacheAsync(OutputCacheContext context, CancellationToken cancellation) => ValueTask.CompletedTask;

    public ValueTask ServeResponseAsync(OutputCacheContext context, CancellationToken cancellation)
    {
        var response = context.HttpContext.Response;
        if (response.StatusCode != StatusCodes.Status200OK || !StringValues.IsNullOrEmpty(response.Headers.SetCookie))
        {
            context.AllowCacheStorage = false;
        }

        return ValueTask.CompletedTask;
    }
}

/// <summary>
/// On an admin controller: after any successful non-GET action, drops every cached reference-data response, so an edit
/// to categories/products/units/mandis/plans/translations shows up on the next request instead of up to 10 min later.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
internal sealed class EvictReferenceDataCacheAttribute : Attribute, Microsoft.AspNetCore.Mvc.Filters.IAsyncResultFilter
{
    public async Task OnResultExecutionAsync(
        Microsoft.AspNetCore.Mvc.Filters.ResultExecutingContext context,
        Microsoft.AspNetCore.Mvc.Filters.ResultExecutionDelegate next)
    {
        var executed = await next();

        var http = executed.HttpContext;
        if (HttpMethods.IsGet(http.Request.Method) || http.Response.StatusCode is < 200 or >= 300)
        {
            return;
        }

        var store = http.RequestServices.GetRequiredService<IOutputCacheStore>();
        await store.EvictByTagAsync(ResponseCachingSetup.ReferenceDataTag, http.RequestAborted);
    }
}
