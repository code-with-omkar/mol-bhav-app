using System.Text;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Infrastructure.Ingestion;

namespace MolBhav.UnitTests.Ingestion;

public sealed class AgmarknetCsvParserTests
{
    private static AgmarknetCsvParser CreateParser(Action<AgmarknetOptions>? configure = null)
    {
        var options = new AgmarknetOptions();
        configure?.Invoke(options);
        return new AgmarknetCsvParser(Options.Create(options));
    }

    private static Task<IngestionFileParseResult> ParseAsync(string csv, Action<AgmarknetOptions>? configure = null, string source = "agmarknet")
    {
        // Excel adds a UTF-8 BOM; include it to prove it is handled.
        var bytes = Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(csv)).ToArray();
        return CreateParser(configure).ParseAsync(source, new MemoryStream(bytes));
    }

    [Fact]
    public async Task DataGovInLayout_MapsEveryColumn()
    {
        const string csv = """
            state,district,market,commodity,variety,grade,arrival_date,min_price,max_price,modal_price
            Maharashtra,Nashik,Lasalgaon,Onion,Red,FAQ,03/10/2026,1200,1800,1550
            """;

        var result = await ParseAsync(csv);

        Assert.True(result.IsSuccess);
        var row = Assert.Single(result.Records);
        Assert.Equal("onion", row.ProductCode);
        Assert.Equal("red", row.VariantCode);
        Assert.Equal("lasalgaon", row.LocationCode);
        Assert.Equal(1200m, row.MinPrice);
        Assert.Equal(1800m, row.MaxPrice);
        Assert.Equal(1550m, row.ModalPrice);
        Assert.Equal(new DateOnly(2026, 10, 3), row.RecordDate);
        Assert.Empty(result.LineErrors);
    }

    [Fact]
    public async Task PortalLayout_WithTitleLinesQuotesAndUnits_IsRead()
    {
        const string csv = """
            Agmarknet Price Report
            Commodity wise, Date: 03-Oct-2026

            Sl no.,Market Name,Commodity,Variety,Arrivals (Tonnes),Min Price (Rs./Quintal),Max Price (Rs./Quintal),Modal Price (Rs./Quintal),Price Date
            1,"Pune(Pimpri)",Tomato,Hybrid,12.5,"1,000","1,600","1,300",03 Oct 2026
            """;

        var result = await ParseAsync(csv, o => o.MarketCodeMap["pune-pimpri"] = "apmc-pune");

        var row = Assert.Single(result.Records);
        Assert.Equal("apmc-pune", row.LocationCode);
        Assert.Equal("tomato", row.ProductCode);
        Assert.Equal(1300m, row.ModalPrice);
        Assert.Equal(12.5m, row.ArrivalQuantity);
        Assert.Equal(new DateOnly(2026, 10, 3), row.RecordDate);
    }

    [Fact]
    public async Task BadRows_BecomeLineErrors_GoodRowsStillImport()
    {
        const string csv = """
            market,commodity,variety,arrival_date,min_price,max_price,modal_price
            Lasalgaon,Onion,FAQ,03/10/2026,1200,1800,1550
            Lasalgaon,Onion,FAQ,not-a-date,1200,1800,1550
            Lasalgaon,,FAQ,03/10/2026,1200,1800,1550
            Lasalgaon,Potato,FAQ,03/10/2026,,,0
            """;

        var result = await ParseAsync(csv);

        Assert.True(result.IsSuccess);
        var good = Assert.Single(result.Records);
        Assert.Null(good.VariantCode); // "FAQ" means no specific variety
        Assert.Equal(3, result.LineErrors.Count);
        Assert.Equal([3, 4, 5], result.LineErrors.Select(e => e.LineNumber));
        Assert.Contains("date", result.LineErrors[0].Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task MissingRequiredColumns_FailsTheWholeFile()
    {
        var result = await ParseAsync("market,commodity,min_price\nLasalgaon,Onion,1200\n");

        Assert.False(result.IsSuccess);
        Assert.Contains("header", result.FailureReason, StringComparison.OrdinalIgnoreCase);
    }
}
