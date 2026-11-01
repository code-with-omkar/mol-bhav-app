using Microsoft.Extensions.Logging.Abstractions;
using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Application.Features.Alerting.Opportunities;
using MolBhav.Application.Features.Alerting.Opportunities.ScanMarketOpportunities;
using MolBhav.Domain.Alerting;
using MolBhav.Domain.Pricing;
using MolBhav.Domain.Procurement;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Alerting;

public sealed class MarketOpportunityScanTests
{
    // 5 Oct 2026, 10:00 IST.
    private static readonly DateTimeOffset Now = new(2026, 10, 5, 4, 30, 0, TimeSpan.Zero);
    private static readonly DateOnly Today = new(2026, 10, 5);
    private static readonly DateOnly Yesterday = Today.AddDays(-1);

    private readonly IMarketOpportunityReadService _read = Substitute.For<IMarketOpportunityReadService>();
    private readonly IMarketOpportunityRepository _opportunities = Substitute.For<IMarketOpportunityRepository>();
    private readonly ICostComponentRepository _costs = Substitute.For<ICostComponentRepository>();
    private readonly IOpportunitySettings _settings = Substitute.For<IOpportunitySettings>();
    private readonly Guid _user = Guid.CreateVersion7();
    private readonly Guid _onion = Guid.CreateVersion7();
    private readonly Guid _red = Guid.CreateVersion7();
    private readonly Guid _white = Guid.CreateVersion7();
    private readonly Guid _pune = Guid.CreateVersion7();
    private readonly Guid _nashik = Guid.CreateVersion7();
    private readonly Guid _punApmc = Guid.CreateVersion7();
    private readonly Guid _lasalgaon = Guid.CreateVersion7();
    private readonly List<MarketOpportunity> _added = [];

    public MarketOpportunityScanTests()
    {
        _settings.MinSavingsPercent.Returns(10m);
        _settings.FreshnessDays.Returns(7);
        _settings.ReferenceQuantity.Returns(10m);
        _costs.GetActiveAsync(Arg.Any<CancellationToken>()).Returns(Array.Empty<CostComponent>());
        _opportunities.GetFoundOnAsync(Today, Arg.Any<CancellationToken>())
            .Returns(new HashSet<(Guid, Guid)>());
        _opportunities.Add(Arg.Do<MarketOpportunity>(_added.Add));
        _read.GetWatchersAsync(Arg.Any<CancellationToken>())
            .Returns([new OpportunityWatcher(_user, _onion, _red, _pune)]);
    }

    private ScanMarketOpportunitiesCommandHandler CreateHandler() =>
        new(_read, _opportunities, _costs, _settings, new FixedTimeProvider(Now), NullLogger<ScanMarketOpportunitiesCommandHandler>.Instance);

    private OpportunityPrice Mandi(Guid mandi, Guid district, decimal price, Guid? variant = null) =>
        new(_onion, variant ?? _red, LocationKind.Mandi, mandi, null, district, price, Yesterday);

    private void GivenPrices(params OpportunityPrice[] prices) =>
        _read.GetLatestPricesAsync(Arg.Any<IReadOnlyCollection<Guid>>(), Arg.Any<DateOnly>(), Arg.Any<CancellationToken>())
            .Returns(prices);

    [Fact]
    public async Task Finds_a_market_at_least_ten_percent_cheaper_than_home()
    {
        GivenPrices(Mandi(_punApmc, _pune, 2400), Mandi(_lasalgaon, _nashik, 2020));

        var result = await CreateHandler().Handle(new ScanMarketOpportunitiesCommand(), CancellationToken.None);

        Assert.Equal(1, result.Value.Found);
        var opportunity = Assert.Single(_added);
        Assert.Equal(_lasalgaon, opportunity.BestMandiId);
        Assert.Equal(_punApmc, opportunity.HomeMandiId);
        Assert.Equal(15.83m, opportunity.SavingsPercent);
        Assert.Equal(Today, opportunity.DetectedOn);
    }

    [Fact]
    public async Task Ignores_a_saving_below_the_threshold()
    {
        GivenPrices(Mandi(_punApmc, _pune, 2400), Mandi(_lasalgaon, _nashik, 2200));

        var result = await CreateHandler().Handle(new ScanMarketOpportunitiesCommand(), CancellationToken.None);

        Assert.Equal(0, result.Value.Found);
        Assert.Empty(_added);
    }

    [Fact]
    public async Task Costs_can_wipe_out_the_saving()
    {
        // 16% cheaper on price, but 8% freight + ₹150/10 units handling leaves under 10%.
        _costs.GetActiveAsync(Arg.Any<CancellationToken>()).Returns(
        [
            CostComponent.Create("freight", "Freight", CostComponentType.Percentage, 8m).Value,
            CostComponent.Create("handling", "Handling", CostComponentType.Fixed, 150m).Value,
        ]);
        GivenPrices(Mandi(_punApmc, _pune, 2400), Mandi(_lasalgaon, _nashik, 2020));

        await CreateHandler().Handle(new ScanMarketOpportunitiesCommand(), CancellationToken.None);

        Assert.Empty(_added);
    }

    [Fact]
    public async Task Needs_a_home_district_price()
    {
        GivenPrices(Mandi(_lasalgaon, _nashik, 2020));

        await CreateHandler().Handle(new ScanMarketOpportunitiesCommand(), CancellationToken.None);

        Assert.Empty(_added);
    }

    [Fact]
    public async Task Never_compares_two_varieties()
    {
        // White is cheap elsewhere, but the user watches red and red has no cheaper market.
        GivenPrices(
            Mandi(_punApmc, _pune, 2400),
            Mandi(_lasalgaon, _nashik, 1500, _white),
            Mandi(_punApmc, _pune, 2700, _white));

        await CreateHandler().Handle(new ScanMarketOpportunitiesCommand(), CancellationToken.None);

        Assert.Empty(_added);
    }

    [Fact]
    public async Task Is_found_at_most_once_a_day_per_product()
    {
        _opportunities.GetFoundOnAsync(Today, Arg.Any<CancellationToken>())
            .Returns(new HashSet<(Guid, Guid)> { (_user, _onion) });
        GivenPrices(Mandi(_punApmc, _pune, 2400), Mandi(_lasalgaon, _nashik, 2020));

        await CreateHandler().Handle(new ScanMarketOpportunitiesCommand(), CancellationToken.None);

        Assert.Empty(_added);
    }

    [Fact]
    public async Task Raises_the_notification_event()
    {
        GivenPrices(Mandi(_punApmc, _pune, 2400), Mandi(_lasalgaon, _nashik, 2020));

        await CreateHandler().Handle(new ScanMarketOpportunitiesCommand(), CancellationToken.None);

        var opportunity = Assert.Single(_added);
        Assert.Contains(opportunity.DomainEvents, e => e is Domain.Alerting.Events.MarketOpportunityFoundDomainEvent);
    }

    [Fact]
    public void Landed_cost_spreads_fixed_costs_over_the_reference_quantity()
    {
        var components = new[]
        {
            CostComponent.Create("freight", "Freight", CostComponentType.Percentage, 5m).Value,
            CostComponent.Create("handling", "Handling", CostComponentType.Fixed, 200m).Value,
        };

        Assert.Equal(2120m, LandedCost.PerUnit(2000m, components, 10m)); // 2000 + 5% + 200/10
    }

    [Fact]
    public void Opportunity_rejects_a_market_that_is_not_cheaper()
    {
        var result = MarketOpportunity.Create(
            _user, _onion, _red, Today,
            MarketLocation.Mandi(_punApmc), 2000m,
            MarketLocation.Mandi(_lasalgaon), 1990m, 2050m,
            Yesterday, Now);

        Assert.True(result.IsFailure);
        Assert.Equal("MarketOpportunity.NoSaving", result.Error.Code);
    }

    [Fact]
    public void Opportunity_rejects_the_same_market_on_both_sides()
    {
        var result = MarketOpportunity.Create(
            _user, _onion, _red, Today,
            MarketLocation.Mandi(_punApmc), 2400m,
            MarketLocation.Mandi(_punApmc), 2000m, 2000m,
            Yesterday, Now);

        Assert.Equal("MarketOpportunity.SameMarket", result.Error.Code);
    }
}
