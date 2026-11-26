using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Ingestion.Common;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Market;
using MolBhav.Domain.Pricing;
using MolBhav.Domain.SharedKernel;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Ingestion;

/// <summary>The feed quotes rupees per quintal; each price is stored per the product's own unit.</summary>
public sealed class IngestionRecordWriterUnitTests
{
    private static readonly DateTimeOffset Now = new(2026, 11, 24, 6, 0, 0, TimeSpan.Zero);
    private static readonly DateOnly Day = new(2026, 11, 24);

    private readonly IProductRepository _products = Substitute.For<IProductRepository>();
    private readonly IProcurementCategoryRepository _categories = Substitute.For<IProcurementCategoryRepository>();
    private readonly IMandiRepository _mandis = Substitute.For<IMandiRepository>();
    private readonly IPriceRecordRepository _records = Substitute.For<IPriceRecordRepository>();
    private readonly IUnitOfMeasureRepository _units = Substitute.For<IUnitOfMeasureRepository>();
    private readonly List<PriceRecord> _stored = [];
    private readonly Guid _categoryId = Guid.CreateVersion7();
    private readonly Guid _subCategoryId = Guid.CreateVersion7();
    private readonly UnitOfMeasure _quintal = Unit("quintal", "q", MeasureDimension.Mass, 100m);
    private readonly UnitOfMeasure _kg = Unit("kg", "kg", MeasureDimension.Mass, 1m);
    private readonly UnitOfMeasure _piece = Unit("piece", "pc", MeasureDimension.Count, 1m);
    private readonly DataIngestionJob _job = DataIngestionJob.Start(Guid.CreateVersion7(), IngestionTriggerType.Scheduled, null, Day, Now).Value;

    public IngestionRecordWriterUnitTests()
    {
        _categories.GetSubCategoryIdsAsync(_categoryId, Arg.Any<CancellationToken>())
            .Returns((IReadOnlySet<Guid>)new HashSet<Guid> { _subCategoryId });
        _mandis.GetByCodeAsync(Arg.Any<MarketCode>(), Arg.Any<CancellationToken>())
            .Returns(Mandi.Create(MarketCode.Create("apmc-pune").Value, Guid.CreateVersion7(), "APMC Pune").Value);
        _records.When(r => r.Add(Arg.Any<PriceRecord>())).Do(call => _stored.Add(call.Arg<PriceRecord>()));
        foreach (var unit in new[] { _quintal, _kg, _piece })
        {
            _units.GetIdByCodeAsync(unit.Code, Arg.Any<CancellationToken>()).Returns(unit.Id);
            _units.GetByIdAsync(unit.Id, Arg.Any<CancellationToken>()).Returns(unit);
        }
    }

    private static UnitOfMeasure Unit(string code, string symbol, MeasureDimension dimension, decimal factor) =>
        UnitOfMeasure.Create(
            CatalogCode.Create(code).Value, symbol, dimension, factor,
            [CatalogTranslation.Create(LanguageCode.English, code).Value]).Value;

    private async Task<IngestionWriteCounts> Write(UnitOfMeasure productUnit, string? quoted)
    {
        var onion = Product.Create(
            CatalogCode.Create("onion").Value, _subCategoryId, productUnit.Id, 1, null,
            [CatalogTranslation.Create(LanguageCode.English, "Onion").Value]).Value;
        _products.GetByCodeAsync(Arg.Any<CatalogCode>(), Arg.Any<CancellationToken>()).Returns(onion);
        var writer = new IngestionRecordWriter(
            Substitute.For<IDataIngestionErrorRepository>(), _records, _products, _categories, _mandis,
            Substitute.For<ISupplierRepository>(), _units, new FixedTimeProvider(Now));
        var row = new IngestedPriceRecord("onion", null, LocationKind.Mandi, "apmc-pune", 4000m, 5000m, 4550m, null, Day, quoted);
        return await writer.WriteAsync(_job, _categoryId, [row], CancellationToken.None);
    }

    [Fact]
    public async Task A_price_per_quintal_is_stored_per_kg_for_a_kg_product()
    {
        await Write(_kg, "quintal");

        var record = Assert.Single(_stored);
        Assert.Equal(45.5m, record.ModalPrice);
        Assert.Equal(40m, record.MinPrice);
        Assert.Equal(50m, record.MaxPrice);
        Assert.Equal(_kg.Id, record.UnitId);
    }

    [Theory]
    [InlineData("quintal")]
    [InlineData(null)]
    public async Task Figures_already_in_the_product_unit_are_unchanged(string? quoted)
    {
        await Write(_quintal, quoted);

        Assert.Equal(4550m, Assert.Single(_stored).ModalPrice);
    }

    [Fact]
    public async Task A_unit_that_cannot_be_converted_is_an_error_not_a_wrong_price()
    {
        var counts = await Write(_piece, "quintal");

        Assert.Equal(1, counts.Failed);
        Assert.Empty(_stored);
    }
}
