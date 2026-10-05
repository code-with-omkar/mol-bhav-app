using System.Text;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Domain.Pricing;
using MolBhav.Infrastructure.Ingestion;

namespace MolBhav.UnitTests.Ingestion;

public sealed class StandardPriceCsvParserTests
{
    private const string Header = StandardPriceCsvParser.TemplateHeader;

    private static MemoryStream Csv(string text) =>
        new(Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(text)).ToArray());

    [Fact]
    public async Task ConstructionAndMandiRows_AreMapped()
    {
        var csv = $"""
            {Header}
            tmt-steel-bar,fe-500d,supplier,pune-steel-traders,,,"62,500",,2026-10-03
            onion,,Mandi,pune-apmc,1800,2600,2200,1450,03/10/2026
            """;

        var result = await new StandardPriceCsvParser().ParseAsync("cpwd-dsr", Csv(csv));

        Assert.True(result.IsSuccess);
        Assert.Empty(result.LineErrors);
        Assert.Equal(2, result.Records.Count);

        var steel = result.Records[0];
        Assert.Equal("tmt-steel-bar", steel.ProductCode);
        Assert.Equal("fe-500d", steel.VariantCode);
        Assert.Equal(LocationKind.Supplier, steel.LocationKind);
        Assert.Equal("pune-steel-traders", steel.LocationCode);
        Assert.Null(steel.MinPrice);
        Assert.Equal(62500m, steel.ModalPrice);
        Assert.Equal(new DateOnly(2026, 10, 3), steel.RecordDate);

        var onion = result.Records[1];
        Assert.Null(onion.VariantCode);
        Assert.Equal(LocationKind.Mandi, onion.LocationKind);
        Assert.Equal(1800m, onion.MinPrice);
        Assert.Equal(1450m, onion.ArrivalQuantity);
        Assert.Equal(new DateOnly(2026, 10, 3), onion.RecordDate);
    }

    [Fact]
    public async Task BadRows_BecomeLineErrors_GoodRowsStillImport()
    {
        var csv = $"""
            {Header}
            cement-opc-53,,depot,pune-cement-depot,,,410,,2026-10-03
            cement-opc-53,,supplier,pune-cement-depot,,,abc,,2026-10-03
            cement-opc-53,,supplier,pune-cement-depot,,,410,,3rd Oct
            cement-opc-53,,supplier,pune-cement-depot,,,410,,2026-10-03
            """;

        var result = await new StandardPriceCsvParser().ParseAsync("supplier-quotes", Csv(csv));

        Assert.True(result.IsSuccess);
        Assert.Single(result.Records);
        Assert.Equal([2, 3, 4], result.LineErrors.Select(e => e.LineNumber));
        Assert.Contains("location_kind", result.LineErrors[0].Message, StringComparison.Ordinal);
        Assert.Contains("modal_price", result.LineErrors[1].Message, StringComparison.Ordinal);
        Assert.Contains("record_date", result.LineErrors[2].Message, StringComparison.Ordinal);
    }

    [Fact]
    public async Task NonTemplateFile_FailsWithTheExpectedHeader()
    {
        var result = await new StandardPriceCsvParser().ParseAsync("cpwd-dsr", Csv("item,rate\nSteel,62500\n"));

        Assert.False(result.IsSuccess);
        Assert.Contains(Header, result.FailureReason, StringComparison.Ordinal);
    }

    [Fact]
    public async Task Dispatcher_RoutesByHeaderThenSourceCode()
    {
        var services = new ServiceCollection();
        services.AddKeyedScoped<IIngestionFileParser>("agmarknet", (_, _) => new AgmarknetCsvParser(Options.Create(new AgmarknetOptions())));
        services.AddKeyedScoped<IIngestionFileParser, StandardPriceCsvParser>(IngestionFileParserDispatcher.StandardKey);
        await using var provider = services.BuildServiceProvider();
        var dispatcher = new IngestionFileParserDispatcher(provider);

        // Agmarknet source + government layout → Agmarknet parser (codes come from the mapper, not the file).
        var gov = await dispatcher.ParseAsync(
            "agmarknet",
            Csv("state,district,market,commodity,variety,grade,arrival_date,min_price,max_price,modal_price\nMaharashtra,Nashik,Lasalgaon,Onion,Red,FAQ,03/10/2026,1500,2500,2100\n"));
        Assert.True(gov.IsSuccess);
        Assert.Single(gov.Records);

        // Agmarknet source + standard template → standard parser.
        var template = await dispatcher.ParseAsync("agmarknet", Csv($"{Header}\nonion,,mandi,lasalgaon,,,2100,,2026-10-03\n"));
        Assert.True(template.IsSuccess);
        Assert.Equal("lasalgaon", template.Records[0].LocationCode);

        // A source with no dedicated parser (a new construction feed) → standard parser.
        var construction = await dispatcher.ParseAsync("cpwd-dsr", Csv($"{Header}\ntmt-steel-bar,,supplier,pune-steel-traders,,,62500,,2026-10-03\n"));
        Assert.True(construction.IsSuccess);
        Assert.Equal(LocationKind.Supplier, construction.Records[0].LocationKind);
    }
}
