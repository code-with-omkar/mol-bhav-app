using System.Text;
using Microsoft.AspNetCore.Http;
using MolBhav.Api.Middleware;

namespace MolBhav.UnitTests.Api;

public sealed class ConditionalGetMiddlewareTests
{
    private const string Json = """{"success":true,"data":[{"code":"onion"}]}""";

    private static async Task<(HttpContext Context, string Body)> InvokeAsync(
        string method = "GET",
        string path = "/api/v1/catalog/categories",
        string? ifNoneMatch = null,
        string contentType = "application/json; charset=utf-8",
        int status = StatusCodes.Status200OK)
    {
        var context = new DefaultHttpContext();
        context.Request.Method = method;
        context.Request.Path = path;
        if (ifNoneMatch is not null)
        {
            context.Request.Headers.IfNoneMatch = ifNoneMatch;
        }

        var output = new MemoryStream();
        context.Response.Body = output;

        var middleware = new ConditionalGetMiddleware(async ctx =>
        {
            ctx.Response.StatusCode = status;
            ctx.Response.ContentType = contentType;
            await ctx.Response.WriteAsync(Json);
        });

        await middleware.InvokeAsync(context);
        return (context, Encoding.UTF8.GetString(output.ToArray()));
    }

    [Fact]
    public async Task JsonGet_GetsAnETagAndThePrivateRevalidateCachePolicy()
    {
        var (context, body) = await InvokeAsync();

        Assert.Equal(Json, body);
        Assert.StartsWith("W/\"", context.Response.Headers.ETag.ToString(), StringComparison.Ordinal);
        Assert.Equal("private, no-cache", context.Response.Headers.CacheControl.ToString());
    }

    [Fact]
    public async Task MatchingIfNoneMatch_Returns304WithoutABody()
    {
        var (first, _) = await InvokeAsync();
        var etag = first.Response.Headers.ETag.ToString();

        var (context, body) = await InvokeAsync(ifNoneMatch: etag);

        Assert.Equal(StatusCodes.Status304NotModified, context.Response.StatusCode);
        Assert.Empty(body);
        Assert.Equal(etag, context.Response.Headers.ETag.ToString());
    }

    [Fact]
    public async Task StaleIfNoneMatch_ReturnsTheFullBody()
    {
        var (context, body) = await InvokeAsync(ifNoneMatch: "W/\"something-else\"");

        Assert.Equal(StatusCodes.Status200OK, context.Response.StatusCode);
        Assert.Equal(Json, body);
    }

    [Theory]
    [InlineData("POST", "/api/v1/alert-rules", "application/json")]
    [InlineData("GET", "/api/v1/reports/1/download", "application/json")]
    [InlineData("GET", "/api/v1/reports/x", "application/pdf")]
    [InlineData("GET", "/health/live", "application/json")]
    public async Task NonJsonGets_DownloadsAndWrites_AreLeftAlone(string method, string path, string contentType)
    {
        var (context, body) = await InvokeAsync(method, path, contentType: contentType);

        Assert.Equal(Json, body);
        Assert.False(context.Response.Headers.ContainsKey("ETag"));
    }

    [Fact]
    public async Task ErrorResponses_GetNoETag()
    {
        var (context, body) = await InvokeAsync(status: StatusCodes.Status404NotFound);

        Assert.Equal(Json, body);
        Assert.False(context.Response.Headers.ContainsKey("ETag"));
    }
}
