using System.Diagnostics;
using System.Net;
using System.Net.Http.Headers;
using System.Text;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using MolBhav.Domain.Ingestion;
using MolBhav.Infrastructure.Ingestion;

namespace MolBhav.UnitTests.Ingestion;

/// <summary>A throttled or briefly unavailable data.gov.in must not fail a whole run: the failing page is retried.</summary>
public sealed class AgmarknetRetryTests
{
    private static string Page(int total, string commodity = "Onion") => $$"""
        { "status": "ok", "total": {{total}}, "count": 1, "limit": "1", "offset": "0",
          "records": [ { "market": "APMC Pune", "commodity": "{{commodity}}", "variety": "Other", "arrival_date": "15/10/2026",
                         "min_price": 1800, "max_price": 2400, "modal_price": 2100 } ] }
        """;

    private static HttpResponseMessage Ok(string body) =>
        new(HttpStatusCode.OK) { Content = new StringContent(body, Encoding.UTF8, "application/json") };

    private static HttpResponseMessage Status(HttpStatusCode code, TimeSpan? retryAfter = null)
    {
        var response = new HttpResponseMessage(code);
        if (retryAfter is { } delta)
        {
            response.Headers.RetryAfter = new RetryConditionHeaderValue(delta);
        }

        return response;
    }

    private sealed class ScriptedHandler(params Func<HttpResponseMessage>[] script) : HttpMessageHandler
    {
        private int _next;

        public List<string> Urls { get; } = [];

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Urls.Add(request.RequestUri!.PathAndQuery);
            return Task.FromResult(script[Math.Min(_next++, script.Length - 1)]());
        }
    }

    private sealed class StubFactory(HttpMessageHandler handler) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => new(handler, disposeHandler: false) { BaseAddress = new Uri("https://api.data.gov.in") };
    }

    private static AgmarknetIngestionSourceAdapter CreateAdapter(
        ScriptedHandler handler, int pageSize = 500, int maxRetries = 2, int maxDelaySeconds = 0) => new(
        new StubFactory(handler),
        Options.Create(new AgmarknetOptions
        {
            ApiKey = "test-key",
            PageSize = pageSize,
            ThrottleDelayMs = 0,
            MaxRetries = maxRetries,
            RetryBaseDelaySeconds = 0,
            MaxRetryDelaySeconds = maxDelaySeconds,
        }),
        NullLogger<AgmarknetIngestionSourceAdapter>.Instance);

    private static Task<MolBhav.Application.Abstractions.Ingestion.IngestionFetchResult> RunFiltered(
        AgmarknetIngestionSourceAdapter adapter, string[]? states = null, string[]? commodities = null, string[]? markets = null) =>
        adapter.FetchAsync(
            new("agmarknet", new DateOnly(2026, 10, 15), IngestionFilter.Create(states, commodities, markets).Value),
            CancellationToken.None);

    [Fact]
    public async Task Without_a_filter_the_whole_feed_is_requested_with_no_filters_but_the_date()
    {
        var handler = new ScriptedHandler(() => Ok(Page(1)));

        await Run(CreateAdapter(handler));

        Assert.Single(handler.Urls);
        Assert.DoesNotContain("state.keyword", handler.Urls[0], StringComparison.Ordinal);
        Assert.DoesNotContain("commodity", handler.Urls[0], StringComparison.Ordinal);
        Assert.DoesNotContain("filters%5Bmarket", handler.Urls[0], StringComparison.Ordinal);
    }

    [Fact]
    public async Task Each_state_is_fetched_on_its_own_from_the_first_page()
    {
        var handler = new ScriptedHandler(() => Ok(Page(1, "Onion")), () => Ok(Page(1, "Potato")));

        var result = await RunFiltered(CreateAdapter(handler), states: ["Maharashtra", "Madhya Pradesh"]);

        Assert.True(result.IsSuccess, result.FailureReason);
        Assert.Equal(["onion", "potato"], result.Records.Select(r => r.ProductCode).Order().ToArray());
        Assert.Equal(2, handler.Urls.Count);
        Assert.Contains("filters%5Bstate.keyword%5D=Maharashtra", handler.Urls[0], StringComparison.Ordinal);
        Assert.Contains("filters%5Bstate.keyword%5D=Madhya%20Pradesh", handler.Urls[1], StringComparison.Ordinal);
        Assert.Contains("offset=0", handler.Urls[1], StringComparison.Ordinal);
    }

    [Fact]
    public async Task States_commodities_and_markets_combine_into_one_request_each()
    {
        var handler = new ScriptedHandler(() => Ok(Page(1)));

        await RunFiltered(CreateAdapter(handler), ["Maharashtra"], ["Onion", "Potato"], ["APMC Pune"]);

        Assert.Equal(2, handler.Urls.Count);
        Assert.All(handler.Urls, u =>
        {
            Assert.Contains("filters%5Bstate.keyword%5D=Maharashtra", u, StringComparison.Ordinal);
            Assert.Contains("filters%5Bmarket%5D=APMC%20Pune", u, StringComparison.Ordinal);
        });
        Assert.Contains("filters%5Bcommodity%5D=Onion", handler.Urls[0], StringComparison.Ordinal);
        Assert.Contains("filters%5Bcommodity%5D=Potato", handler.Urls[1], StringComparison.Ordinal);
    }

    [Fact]
    public async Task A_failure_in_a_later_pass_fails_the_run_rather_than_returning_part_of_the_data()
    {
        var handler = new ScriptedHandler(() => Ok(Page(1)), () => Status(HttpStatusCode.Unauthorized));

        var result = await RunFiltered(CreateAdapter(handler), states: ["Maharashtra", "Madhya Pradesh"]);

        Assert.False(result.IsSuccess);
        Assert.Empty(result.Records);
    }

    private static Task<MolBhav.Application.Abstractions.Ingestion.IngestionFetchResult> Run(AgmarknetIngestionSourceAdapter adapter) =>
        adapter.FetchAsync(new("agmarknet", new DateOnly(2026, 10, 15)), CancellationToken.None);

    [Fact]
    public async Task Too_many_requests_is_retried_and_the_run_succeeds()
    {
        var handler = new ScriptedHandler(() => Status(HttpStatusCode.TooManyRequests), () => Ok(Page(1)));

        var result = await Run(CreateAdapter(handler));

        Assert.True(result.IsSuccess, result.FailureReason);
        Assert.Single(result.Records);
        Assert.Equal(2, handler.Urls.Count);
    }

    [Theory]
    [InlineData(HttpStatusCode.BadGateway)]
    [InlineData(HttpStatusCode.ServiceUnavailable)]
    [InlineData(HttpStatusCode.GatewayTimeout)]
    public async Task Other_transient_statuses_are_retried_too(HttpStatusCode status)
    {
        var handler = new ScriptedHandler(() => Status(status), () => Ok(Page(1)));

        var result = await Run(CreateAdapter(handler));

        Assert.True(result.IsSuccess, result.FailureReason);
        Assert.Equal(2, handler.Urls.Count);
    }

    [Fact]
    public async Task Gives_up_after_the_configured_retries_with_the_status_in_the_reason()
    {
        var handler = new ScriptedHandler(() => Status(HttpStatusCode.TooManyRequests));

        var result = await Run(CreateAdapter(handler, maxRetries: 2));

        Assert.False(result.IsSuccess);
        Assert.Contains("429", result.FailureReason, StringComparison.Ordinal);
        Assert.Equal(3, handler.Urls.Count); // first try + 2 retries
    }

    [Fact]
    public async Task Retries_can_be_turned_off()
    {
        var handler = new ScriptedHandler(() => Status(HttpStatusCode.TooManyRequests), () => Ok(Page(1)));

        var result = await Run(CreateAdapter(handler, maxRetries: 0));

        Assert.False(result.IsSuccess);
        Assert.Single(handler.Urls);
    }

    [Fact]
    public async Task A_rejected_key_is_not_retried()
    {
        var handler = new ScriptedHandler(() => Status(HttpStatusCode.Unauthorized), () => Ok(Page(1)));

        var result = await Run(CreateAdapter(handler));

        Assert.False(result.IsSuccess);
        Assert.Contains("invalid or unauthorised", result.FailureReason, StringComparison.Ordinal);
        Assert.Single(handler.Urls);
    }

    [Fact]
    public async Task A_throttled_page_is_retried_in_place_not_from_the_start()
    {
        // Two pages of one row each; the second is throttled once. The retry must ask for offset 1 again, not restart at 0.
        var handler = new ScriptedHandler(() => Ok(Page(2)), () => Status(HttpStatusCode.TooManyRequests), () => Ok(Page(2, "Potato")));

        var result = await Run(CreateAdapter(handler, pageSize: 1));

        Assert.True(result.IsSuccess, result.FailureReason);
        Assert.Equal(2, result.Records.Count);
        Assert.Equal(3, handler.Urls.Count);
        Assert.Contains("offset=0", handler.Urls[0], StringComparison.Ordinal);
        Assert.Contains("offset=1", handler.Urls[1], StringComparison.Ordinal);
        Assert.Contains("offset=1", handler.Urls[2], StringComparison.Ordinal);
    }

    // The client timeout surfaces as a TaskCanceledException that nobody asked for.
    private static HttpResponseMessage TimedOut() => throw new TaskCanceledException("The request was canceled due to the configured HttpClient.Timeout.");

    [Fact]
    public async Task A_stalled_request_is_retried_and_the_run_succeeds()
    {
        var handler = new ScriptedHandler(TimedOut, () => Ok(Page(1)));

        var result = await Run(CreateAdapter(handler));

        Assert.True(result.IsSuccess, result.FailureReason);
        Assert.Equal(2, handler.Urls.Count);
    }

    [Fact]
    public async Task Repeated_timeouts_fail_as_timed_out_not_as_cancelled()
    {
        var handler = new ScriptedHandler(TimedOut);

        var result = await Run(CreateAdapter(handler, maxRetries: 2));

        Assert.False(result.IsSuccess);
        Assert.Contains("timed out", result.FailureReason, StringComparison.Ordinal);
        Assert.DoesNotContain("cancelled", result.FailureReason, StringComparison.OrdinalIgnoreCase);
        Assert.Equal(3, handler.Urls.Count);
    }

    [Fact]
    public async Task A_dropped_connection_is_retried()
    {
        var handler = new ScriptedHandler(() => throw new HttpRequestException("Connection reset by peer"), () => Ok(Page(1)));

        var result = await Run(CreateAdapter(handler));

        Assert.True(result.IsSuccess, result.FailureReason);
        Assert.Equal(2, handler.Urls.Count);
    }

    [Fact]
    public async Task A_real_cancellation_is_not_retried_and_stays_a_cancellation()
    {
        using var cts = new CancellationTokenSource();
        var handler = new ScriptedHandler(() =>
        {
            cts.Cancel();
            throw new TaskCanceledException();
        });

        var result = await CreateAdapter(handler).FetchAsync(new("agmarknet", new DateOnly(2026, 10, 15)), cts.Token);

        Assert.False(result.IsSuccess);
        Assert.Contains("cancelled", result.FailureReason, StringComparison.OrdinalIgnoreCase);
        Assert.Single(handler.Urls);
    }

    [Fact]
    public async Task A_huge_retry_after_is_capped_by_the_maximum_delay()
    {
        var handler = new ScriptedHandler(() => Status(HttpStatusCode.TooManyRequests, TimeSpan.FromHours(1)), () => Ok(Page(1)));

        var clock = Stopwatch.StartNew();
        var result = await Run(CreateAdapter(handler, maxDelaySeconds: 0));

        Assert.True(result.IsSuccess, result.FailureReason);
        Assert.True(clock.Elapsed < TimeSpan.FromSeconds(10), $"Waited {clock.Elapsed} despite the cap.");
    }
}
