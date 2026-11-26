using Microsoft.Extensions.Logging.Abstractions;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Ingestion.Common;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Market;
using MolBhav.Domain.Pricing;

namespace MolBhav.UnitTests.Ingestion;

public sealed class FeedCatalogAutoAddTests
{
    private static readonly DateTimeOffset Now = new(2026, 11, 25, 6, 0, 0, TimeSpan.Zero);

    private readonly IFeedAutoAddSettings _settings = Substitute.For<IFeedAutoAddSettings>();
    private readonly IPriceSourceRepository _sources = Substitute.For<IPriceSourceRepository>();
    private readonly ISourceFeedOptionsRepository _feedOptions = Substitute.For<ISourceFeedOptionsRepository>();
    private readonly IStateRepository _states = Substitute.For<IStateRepository>();
    private readonly IMandiRepository _mandis = Substitute.For<IMandiRepository>();
    private readonly IFeedMarketCodes _codes = Substitute.For<IFeedMarketCodes>();
    private readonly IProductRepository _products = Substitute.For<IProductRepository>();
    private readonly IProcurementCategoryRepository _categories = Substitute.For<IProcurementCategoryRepository>();
    private readonly IUnitOfMeasureRepository _units = Substitute.For<IUnitOfMeasureRepository>();
    private readonly IUnitOfWork _unitOfWork = Substitute.For<IUnitOfWork>();
    private readonly PriceSource _source = PriceSource.Create("agmarknet", "Agmarknet", Guid.CreateVersion7()).Value;
    private readonly Guid _subCategory = Guid.CreateVersion7();
    private readonly Guid _unit = Guid.CreateVersion7();
    private readonly FeedNames _names = new(["Onion"], [new FeedMarket("Rajkot", "Gujarat", "Rajkot")]);

    public FeedCatalogAutoAddTests()
    {
        _settings.AddMarkets.Returns(true);
        _settings.AddCommodities.Returns(true);
        _settings.CommoditySubCategoryCode.Returns("vegetables");
        _settings.CommodityUnitCode.Returns("quintal");
        _sources.GetByIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns(_source);
        _feedOptions.GetByPriceSourceIdAsync(_source.Id, Arg.Any<CancellationToken>())
            .Returns(SourceFeedOptions.Create(_source.Id, _names.Commodities, _names.Markets, Now).Value);
        _codes.CodeFor(Arg.Any<string>(), Arg.Any<string>()).Returns(call => call.ArgAt<string>(0).ToLowerInvariant());
        _codes.StateNameFor(Arg.Any<string>()).Returns(call => call.Arg<string>().Trim());
        _codes.DistrictNameFor(Arg.Any<string>(), Arg.Any<string>()).Returns(call => call.ArgAt<string>(1).Trim());
        _codes.ProductCodeFor(Arg.Any<string>()).Returns(call => call.Arg<string>().ToLowerInvariant());
        _categories.GetSubCategoryIdByCodeAsync(Arg.Any<CatalogCode>(), Arg.Any<CancellationToken>()).Returns(_subCategory);
        _categories.SubCategoryExistsAsync(_subCategory, Arg.Any<CancellationToken>()).Returns(true);
        _units.GetIdByCodeAsync(Arg.Any<CatalogCode>(), Arg.Any<CancellationToken>()).Returns(_unit);
        _units.ExistsAsync(_unit, Arg.Any<CancellationToken>()).Returns(true);
    }

    private FeedCatalogAutoAdd Create() => new(
        _settings, _sources, _feedOptions, _states, _mandis, _codes, _products, _categories, _units, _unitOfWork,
        NullLogger<FeedCatalogAutoAdd>.Instance);

    [Fact]
    public async Task New_markets_are_added_and_new_commodities_start_hidden()
    {
        await Create().AddNewAsync(_source.Id, _names, CancellationToken.None);

        _mandis.Received(1).Add(Arg.Is<Mandi>(m => m.Name == "Rajkot"));
        _products.Received(1).Add(Arg.Is<Product>(p => p.Code.Value == "onion" && !p.IsActive));
        await _unitOfWork.Received().SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Switched_off_it_touches_nothing()
    {
        _settings.AddMarkets.Returns(false);
        _settings.AddCommodities.Returns(false);

        await Create().AddNewAsync(_source.Id, _names, CancellationToken.None);

        _mandis.DidNotReceive().Add(Arg.Any<Mandi>());
        _products.DidNotReceive().Add(Arg.Any<Product>());
        await _unitOfWork.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task A_missing_default_unit_adds_no_commodities_but_still_adds_markets()
    {
        _units.GetIdByCodeAsync(Arg.Any<CatalogCode>(), Arg.Any<CancellationToken>()).Returns((Guid?)null);

        await Create().AddNewAsync(_source.Id, _names, CancellationToken.None);

        _mandis.Received(1).Add(Arg.Any<Mandi>());
        _products.DidNotReceive().Add(Arg.Any<Product>());
    }
}
