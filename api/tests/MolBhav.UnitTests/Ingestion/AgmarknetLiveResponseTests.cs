using System.Net;
using System.Text;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using MolBhav.Infrastructure.Ingestion;

namespace MolBhav.UnitTests.Ingestion;

/// <summary>
/// The live data.gov.in payload differs from the old fixture: <c>limit</c>/<c>offset</c> are strings and prices are JSON
/// numbers. A first real run failed with "The JSON value could not be converted to System.String" — this pins the shape.
/// </summary>
public sealed class AgmarknetLiveResponseTests
{
    private const string LivePage = """
        {
          "status": "ok", "message": "Resource lists", "total": 2, "count": 2, "limit": "500", "offset": "0",
          "records": [
            { "state": "Maharashtra", "district": "Pune", "market": "APMC Pune", "commodity": "Onion", "variety": "Other",
              "grade": "FAQ", "arrival_date": "15/10/2026", "min_price": 1800, "max_price": 2400, "modal_price": 2100 },
            { "state": "Maharashtra", "district": "Pune", "market": "APMC Pune", "commodity": "Potato", "variety": "Other",
              "grade": "FAQ", "arrival_date": "15/10/2026", "min_price": "1500", "max_price": "2000.50", "modal_price": "1750" }
          ]
        }
        """;

    private sealed class StubHandler(string body) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) =>
            Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(body, Encoding.UTF8, "application/json"),
            });
    }

    private sealed class StubFactory(HttpMessageHandler handler) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => new(handler, disposeHandler: false) { BaseAddress = new Uri("https://api.data.gov.in") };
    }

    private static AgmarknetIngestionSourceAdapter CreateAdapter(string body) => new(
        new StubFactory(new StubHandler(body)),
        Options.Create(new AgmarknetOptions { ApiKey = "test-key", PageSize = 500, ThrottleDelayMs = 0 }),
        NullLogger<AgmarknetIngestionSourceAdapter>.Instance);

    [Fact]
    public async Task A_full_pull_reports_the_states_markets_and_commodities_the_feed_contained()
    {
        var result = await CreateAdapter(LivePage).FetchAsync(new("agmarknet", new DateOnly(2026, 10, 15)), CancellationToken.None);

        var names = result.FeedNames!;
        Assert.Equal(["Onion", "Potato"], names.Commodities.Order().ToArray());
        // The district the feed puts the market in is kept too, so the market can be added to the catalog.
        Assert.Equal(new MolBhav.Domain.Ingestion.FeedMarket("APMC Pune", "Maharashtra", "Pune"), Assert.Single(names.Markets));
    }

    [Fact]
    public async Task A_filtered_pull_reports_no_names_because_it_saw_only_a_slice()
    {
        var filter = MolBhav.Domain.Ingestion.IngestionFilter.Create(["Maharashtra"], null, null).Value;

        var result = await CreateAdapter(LivePage).FetchAsync(new("agmarknet", new DateOnly(2026, 10, 15), filter), CancellationToken.None);

        Assert.True(result.IsSuccess, result.FailureReason);
        Assert.Null(result.FeedNames);
    }

    [Fact]
    public async Task Live_shaped_page_with_string_limit_and_numeric_prices_is_read()
    {
        var result = await CreateAdapter(LivePage).FetchAsync(new("agmarknet", new DateOnly(2026, 10, 15)), CancellationToken.None);

        Assert.True(result.IsSuccess, result.FailureReason);
        Assert.Equal(2, result.Records.Count);

        var onion = result.Records.Single(r => r.ProductCode == "onion");
        Assert.Equal(1800m, onion.MinPrice);
        Assert.Equal(2400m, onion.MaxPrice);
        Assert.Equal(2100m, onion.ModalPrice);
        Assert.Equal("apmc-pune", onion.LocationCode);
        Assert.Equal(new DateOnly(2026, 10, 15), onion.RecordDate);

        // String prices (older shape) still parse, decimals included.
        var potato = result.Records.Single(r => r.ProductCode == "potato");
        Assert.Equal(2000.50m, potato.MaxPrice);
        Assert.Equal(1750m, potato.ModalPrice);
    }

    [Fact]
    public async Task Null_price_fields_do_not_fail_the_page()
    {
        const string body = """
            { "status": "ok", "total": 1, "count": 1, "limit": "500", "offset": "0",
              "records": [ { "market": "APMC Pune", "commodity": "Onion", "variety": "Other", "arrival_date": "15/10/2026",
                             "min_price": null, "max_price": null, "modal_price": 2100 } ] }
            """;

        var result = await CreateAdapter(body).FetchAsync(new("agmarknet", new DateOnly(2026, 10, 15)), CancellationToken.None);

        Assert.True(result.IsSuccess, result.FailureReason);
        var row = Assert.Single(result.Records);
        Assert.Null(row.MinPrice);
        Assert.Equal(2100m, row.ModalPrice);
    }
}
