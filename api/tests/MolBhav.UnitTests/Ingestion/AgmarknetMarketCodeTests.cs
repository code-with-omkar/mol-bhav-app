using System.Text;
using Microsoft.Extensions.Options;
using MolBhav.Infrastructure.Ingestion;

namespace MolBhav.UnitTests.Ingestion;

/// <summary>Two states can have a market of the same name; a "State/slug" map entry keeps their prices apart.</summary>
public sealed class AgmarknetMarketCodeTests
{
    private readonly AgmarknetOptions _options = new();

    public AgmarknetMarketCodeTests()
    {
        _options.StateNameMap["Keralam"] = "Kerala";
        _options.MarketCodeMap["sagar-apmc"] = "sagar-apmc";
        _options.MarketCodeMap["Madhya Pradesh/sagar-apmc"] = "sagar-apmc-madhya";
        _options.MarketCodeMap["Kerala/palakkad-apmc"] = "palakkad-market";
    }

    [Theory]
    [InlineData("Karnataka", "sagar-apmc")]
    [InlineData("Madhya Pradesh", "sagar-apmc-madhya")]
    [InlineData(" madhya pradesh ", "sagar-apmc-madhya")]
    [InlineData(null, "sagar-apmc")]
    [InlineData("", "sagar-apmc")]
    public void The_state_decides_which_market_a_shared_name_means(string? state, string expected) =>
        Assert.Equal(expected, AgmarknetRowMapper.ToMarketCode("Sagar APMC", _options, state));

    [Fact]
    public void Another_spelling_of_the_state_uses_the_same_entry() =>
        Assert.Equal("palakkad-market", AgmarknetRowMapper.ToMarketCode("Palakkad APMC", _options, "Keralam"));

    [Fact]
    public void A_plain_entry_still_applies_in_every_state()
    {
        _options.MarketCodeMap["pune"] = "apmc-pune";

        Assert.Equal("apmc-pune", AgmarknetRowMapper.ToMarketCode("Pune", _options, "Maharashtra"));
    }

    [Fact]
    public async Task An_uploaded_file_is_matched_by_its_state_column()
    {
        const string csv = """
            state,district,market,commodity,variety,arrival_date,min_price,max_price,modal_price
            Karnataka,Shivamogga,Sagar APMC,Onion,Other,24/11/2026,1000,1200,1100
            Madhya Pradesh,Sagar,Sagar APMC,Onion,Other,24/11/2026,900,1100,1000
            """;
        var parser = new AgmarknetCsvParser(Options.Create(_options));
        using var content = new MemoryStream(Encoding.UTF8.GetBytes(csv));

        var result = await parser.ParseAsync("agmarknet", content);

        Assert.Equal(["sagar-apmc", "sagar-apmc-madhya"], result.Records.Select(r => r.LocationCode));
    }
}
