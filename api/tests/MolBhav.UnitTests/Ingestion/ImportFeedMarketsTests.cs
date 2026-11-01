using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Market.Admin.ImportFeedMarkets;
using MolBhav.Application.Features.Market.Models;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Market;
using MolBhav.Domain.Pricing;

namespace MolBhav.UnitTests.Ingestion;

public sealed class ImportFeedMarketsTests
{
    private static readonly DateTimeOffset Now = new(2026, 11, 1, 6, 0, 0, TimeSpan.Zero);

    private readonly IPriceSourceRepository _sources = Substitute.For<IPriceSourceRepository>();
    private readonly ISourceFeedOptionsRepository _feedOptions = Substitute.For<ISourceFeedOptionsRepository>();
    private readonly IStateRepository _states = Substitute.For<IStateRepository>();
    private readonly IMandiRepository _mandis = Substitute.For<IMandiRepository>();
    private readonly IFeedMarketCodes _codes = Substitute.For<IFeedMarketCodes>();
    private readonly PriceSource _source = PriceSource.Create("agmarknet", "Agmarknet", Guid.CreateVersion7()).Value;
    private readonly State _state = State.Create("Gujarat", "GJ").Value;
    private readonly ImportFeedMarketsCommandHandler _handler;

    public ImportFeedMarketsTests()
    {
        _sources.GetByIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns(_source);
        _states.GetByNameAsync(Arg.Any<string>(), Arg.Any<CancellationToken>()).Returns(_state);
        _mandis.CodeExistsAsync(Arg.Any<MarketCode>(), Arg.Any<CancellationToken>()).Returns(false);
        // The same slug rule ingestion uses, without the config map.
        _codes.CodeFor(Arg.Any<string>()).Returns(call => call.Arg<string>().ToLowerInvariant().Replace(' ', '-'));
        _handler = new ImportFeedMarketsCommandHandler(_sources, _feedOptions, _states, _mandis, _codes);
        WithFeed(
            new FeedMarket("Rajkot", "Gujarat", "Rajkot"),
            new FeedMarket("Anand", "Gujarat", "Anand"),
            new FeedMarket("Unjha", "Gujarat", "Mehsana"),
            new FeedMarket("Pune", "Maharashtra", "Pune"));
    }

    private void WithFeed(params FeedMarket[] markets) =>
        _feedOptions.GetByPriceSourceIdAsync(_source.Id, Arg.Any<CancellationToken>())
            .Returns(SourceFeedOptions.Create(_source.Id, ["Onion"], markets, Now).Value);

    private Task<MolBhav.Domain.Common.Results.Result<ImportFeedMarketsResponse>> Import(params string[] markets) =>
        _handler.Handle(new ImportFeedMarketsCommand(_source.Id, "Gujarat", markets), CancellationToken.None);

    [Fact]
    public async Task Markets_are_added_with_the_code_ingestion_uses_and_their_district()
    {
        var result = await Import("Rajkot", "Unjha");

        Assert.True(result.IsSuccess);
        Assert.Equal(2, result.Value.Created);
        Assert.Empty(result.Value.Skipped);
        _mandis.Received(1).Add(Arg.Is<Mandi>(m => m.Code.Value == "rajkot" && m.Name == "Rajkot"));
        _mandis.Received(1).Add(Arg.Is<Mandi>(m => m.Code.Value == "unjha"));
        Assert.Contains(_state.Districts, d => d.Name == "Rajkot");
        Assert.Contains(_state.Districts, d => d.Name == "Mehsana");
    }

    [Fact]
    public async Task An_existing_district_is_reused_whatever_its_case()
    {
        _state.AddDistrict("RAJKOT");

        await Import("Rajkot");

        Assert.Single(_state.Districts, d => string.Equals(d.Name, "Rajkot", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public async Task A_market_already_in_the_catalog_is_skipped_not_duplicated()
    {
        _mandis.CodeExistsAsync(Arg.Is<MarketCode>(c => c.Value == "anand"), Arg.Any<CancellationToken>()).Returns(true);

        var result = await Import("Anand", "Rajkot");

        Assert.Equal(1, result.Value.Created);
        var skipped = Assert.Single(result.Value.Skipped);
        Assert.Equal(new SkippedFeedMarket("Anand", FeedMarketSkipReason.AlreadyInCatalog), skipped);
    }

    [Fact]
    public async Task A_market_not_in_that_states_feed_list_is_skipped()
    {
        // Pune is in the feed list, but under Maharashtra.
        var result = await Import("Pune", "Nowhere");

        Assert.Equal(0, result.Value.Created);
        Assert.All(result.Value.Skipped, s => Assert.Equal(FeedMarketSkipReason.NotInFeed, s.Reason));
        Assert.Equal(2, result.Value.Skipped.Count);
        _mandis.DidNotReceive().Add(Arg.Any<Mandi>());
    }

    [Fact]
    public async Task Two_names_that_resolve_to_one_code_add_only_the_first()
    {
        WithFeed(new FeedMarket("Bhuj", "Gujarat", "Kachchh"), new FeedMarket("bhuj", "Gujarat", "Kutch"));
        _codes.CodeFor(Arg.Any<string>()).Returns("bhuj");

        var result = await Import("Bhuj", "bhuj");

        // The same name in different case is one market; both spellings share a code.
        Assert.Equal(1, result.Value.Created);
    }

    [Fact]
    public async Task A_name_that_cannot_be_a_code_is_skipped()
    {
        WithFeed(new FeedMarket("123 Mandi", "Gujarat", "Rajkot"));
        _codes.CodeFor("123 Mandi").Returns("123-mandi");

        var result = await Import("123 Mandi");

        Assert.Equal(FeedMarketSkipReason.CodeInvalid, Assert.Single(result.Value.Skipped).Reason);
    }

    [Fact]
    public async Task A_market_without_a_district_is_skipped()
    {
        WithFeed(new FeedMarket("Rajkot", "Gujarat"));

        var result = await Import("Rajkot");

        Assert.Equal(FeedMarketSkipReason.DistrictUnknown, Assert.Single(result.Value.Skipped).Reason);
        _mandis.DidNotReceive().Add(Arg.Any<Mandi>());
    }

    [Fact]
    public async Task Without_a_saved_feed_list_the_admin_is_told_to_run_a_full_pull()
    {
        _feedOptions.GetByPriceSourceIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns((SourceFeedOptions?)null);

        var result = await Import("Rajkot");

        Assert.Equal("FeedMarkets.NoFeedList", result.Error.Code);
    }

    [Fact]
    public async Task A_state_missing_from_the_catalog_is_reported_not_invented()
    {
        _states.GetByNameAsync(Arg.Any<string>(), Arg.Any<CancellationToken>()).Returns((State?)null);

        var result = await Import("Rajkot");

        Assert.Equal("FeedMarkets.StateNotInCatalog", result.Error.Code);
    }

    [Fact]
    public async Task Only_the_agmarknet_source_can_be_used()
    {
        var other = PriceSource.Create("supplier-quotes", "Supplier quotes", Guid.CreateVersion7()).Value;
        _sources.GetByIdAsync(other.Id, Arg.Any<CancellationToken>()).Returns(other);

        var result = await _handler.Handle(new ImportFeedMarketsCommand(other.Id, "Gujarat", ["Rajkot"]), CancellationToken.None);

        Assert.Equal("FeedMarkets.SourceNotSupported", result.Error.Code);
    }

    [Fact]
    public async Task An_unknown_source_is_not_found()
    {
        var result = await _handler.Handle(new ImportFeedMarketsCommand(Guid.NewGuid(), "Gujarat", ["Rajkot"]), CancellationToken.None);

        Assert.Equal("PriceSource.NotFound", result.Error.Code);
    }

    [Fact]
    public void The_validator_needs_a_state_and_between_one_and_two_hundred_markets()
    {
        var validator = new ImportFeedMarketsCommandValidator();

        Assert.True(validator.Validate(new ImportFeedMarketsCommand(_source.Id, "Gujarat", ["Rajkot"])).IsValid);
        Assert.False(validator.Validate(new ImportFeedMarketsCommand(_source.Id, "", ["Rajkot"])).IsValid);
        Assert.False(validator.Validate(new ImportFeedMarketsCommand(_source.Id, "Gujarat", [])).IsValid);
        Assert.False(validator.Validate(new ImportFeedMarketsCommand(_source.Id, "Gujarat", null)).IsValid);
        Assert.False(validator.Validate(new ImportFeedMarketsCommand(
            _source.Id, "Gujarat", [.. Enumerable.Range(0, ImportFeedMarketsCommandValidator.MaxMarkets + 1).Select(i => $"M{i}")])).IsValid);
    }
}
