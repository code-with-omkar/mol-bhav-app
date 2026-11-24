using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Market.Admin.ImportAllFeedMarkets;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Market;
using MolBhav.Domain.Pricing;

namespace MolBhav.UnitTests.Ingestion;

public sealed class ImportAllFeedMarketsTests
{
    private static readonly DateTimeOffset Now = new(2026, 11, 24, 6, 0, 0, TimeSpan.Zero);

    private readonly IPriceSourceRepository _sources = Substitute.For<IPriceSourceRepository>();
    private readonly ISourceFeedOptionsRepository _feedOptions = Substitute.For<ISourceFeedOptionsRepository>();
    private readonly IStateRepository _states = Substitute.For<IStateRepository>();
    private readonly IMandiRepository _mandis = Substitute.For<IMandiRepository>();
    private readonly IFeedMarketCodes _codes = Substitute.For<IFeedMarketCodes>();
    private readonly PriceSource _source = PriceSource.Create("agmarknet", "Agmarknet", Guid.CreateVersion7()).Value;
    private readonly ImportAllFeedMarketsCommandHandler _handler;

    public ImportAllFeedMarketsTests()
    {
        _sources.GetByIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns(_source);
        _states.GetByNameAsync(Arg.Any<string>(), Arg.Any<CancellationToken>()).Returns((State?)null);
        _states.CodeExistsAsync(Arg.Any<string>(), Arg.Any<CancellationToken>()).Returns(false);
        _mandis.CodeExistsAsync(Arg.Any<MarketCode>(), Arg.Any<CancellationToken>()).Returns(false);
        _codes.CodeFor(Arg.Any<string>()).Returns(call => call.Arg<string>().ToLowerInvariant().Replace(' ', '-'));
        _handler = new ImportAllFeedMarketsCommandHandler(_sources, _feedOptions, _states, _mandis, _codes);
    }

    private void WithFeed(params FeedMarket[] markets) =>
        _feedOptions.GetByPriceSourceIdAsync(_source.Id, Arg.Any<CancellationToken>())
            .Returns(SourceFeedOptions.Create(_source.Id, ["Onion"], markets, Now).Value);

    [Fact]
    public async Task Missing_states_are_created_and_every_market_is_added()
    {
        WithFeed(
            new FeedMarket("Rajkot", "Gujarat", "Rajkot"),
            new FeedMarket("Anand", "Gujarat", "Anand"),
            new FeedMarket("Indore", "Madhya Pradesh", "Indore"));

        var result = await _handler.Handle(new ImportAllFeedMarketsCommand(_source.Id), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(2, result.Value.StatesCreated);
        Assert.Equal(3, result.Value.MarketsCreated);
        _states.Received(1).Add(Arg.Is<State>(s => s.Name == "Gujarat" && s.Code == "GUJ"));
        _states.Received(1).Add(Arg.Is<State>(s => s.Name == "Madhya Pradesh" && s.Code == "MP"));
        _mandis.Received(3).Add(Arg.Any<Mandi>());
    }

    [Fact]
    public async Task An_existing_state_is_reused_not_recreated()
    {
        var gujarat = State.Create("Gujarat", "GJ").Value;
        _states.GetByNameAsync("Gujarat", Arg.Any<CancellationToken>()).Returns(gujarat);
        WithFeed(new FeedMarket("Rajkot", "Gujarat", "Rajkot"));

        var result = await _handler.Handle(new ImportAllFeedMarketsCommand(_source.Id), CancellationToken.None);

        Assert.Equal(0, result.Value.StatesCreated);
        Assert.Equal(1, result.Value.MarketsCreated);
        _states.DidNotReceive().Add(Arg.Any<State>());
    }

    [Fact]
    public async Task A_market_name_shared_by_two_states_is_added_once()
    {
        WithFeed(
            new FeedMarket("Bijapur", "Karnataka", "Vijayapura"),
            new FeedMarket("Bijapur", "Chhattisgarh", "Bijapur"));

        var result = await _handler.Handle(new ImportAllFeedMarketsCommand(_source.Id), CancellationToken.None);

        Assert.Equal(1, result.Value.MarketsCreated);
        Assert.Equal(1, result.Value.AlreadyInCatalog);
        _mandis.Received(1).Add(Arg.Any<Mandi>());
    }

    [Fact]
    public async Task Markets_already_in_the_catalog_are_counted_not_duplicated()
    {
        _mandis.CodeExistsAsync(Arg.Is<MarketCode>(c => c.Value == "anand"), Arg.Any<CancellationToken>()).Returns(true);
        WithFeed(new FeedMarket("Rajkot", "Gujarat", "Rajkot"), new FeedMarket("Anand", "Gujarat", "Anand"));

        var result = await _handler.Handle(new ImportAllFeedMarketsCommand(_source.Id), CancellationToken.None);

        Assert.Equal(1, result.Value.MarketsCreated);
        Assert.Equal(1, result.Value.AlreadyInCatalog);
    }

    [Fact]
    public async Task Without_a_saved_feed_list_it_says_to_run_a_full_pull()
    {
        _feedOptions.GetByPriceSourceIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns((SourceFeedOptions?)null);

        var result = await _handler.Handle(new ImportAllFeedMarketsCommand(_source.Id), CancellationToken.None);

        Assert.Equal("FeedMarkets.NoFeedList", result.Error.Code);
    }

    [Theory]
    [InlineData("Madhya Pradesh", "MP")]
    [InlineData("Goa", "GOA")]
    [InlineData("Andaman and Nicobar", "AN")]
    [InlineData("Uttar Pradesh", "UP")]
    public void State_codes_start_with_a_short_readable_form(string name, string expected) =>
        Assert.Equal(expected, ImportAllFeedMarketsCommandHandler.StateCodeCandidates(name).First());

    [Fact]
    public void State_code_candidates_stay_within_ten_letters_or_digits()
    {
        var all = ImportAllFeedMarketsCommandHandler.StateCodeCandidates("Dadra and Nagar Haveli and Daman and Diu").ToList();

        Assert.All(all, c =>
        {
            Assert.InRange(c.Length, 2, 10);
            Assert.All(c, ch => Assert.True(char.IsAsciiLetterOrDigit(ch)));
        });
        Assert.Equal(all.Count, all.Distinct().Count());
    }
}
