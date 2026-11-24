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

/// <summary>A national feed is ~12,000 rows: the writer must not ask the database about every row.</summary>
public sealed class IngestionRecordWriterBatchTests
{
    private static readonly DateTimeOffset Now = new(2026, 11, 24, 6, 0, 0, TimeSpan.Zero);
    private static readonly DateOnly Day = new(2026, 11, 24);

    private readonly IDataIngestionErrorRepository _errors = Substitute.For<IDataIngestionErrorRepository>();
    private readonly IProductRepository _products = Substitute.For<IProductRepository>();
    private readonly IProcurementCategoryRepository _categories = Substitute.For<IProcurementCategoryRepository>();
    private readonly IMandiRepository _mandis = Substitute.For<IMandiRepository>();
    private readonly IPriceRecordRepository _records = Substitute.For<IPriceRecordRepository>();
    private readonly Guid _categoryId = Guid.CreateVersion7();
    private readonly Guid _subCategoryId = Guid.CreateVersion7();
    private readonly DataIngestionJob _job = DataIngestionJob.Start(Guid.CreateVersion7(), IngestionTriggerType.Scheduled, null, Day, Now).Value;
    private readonly Product _onion;
    private readonly Dictionary<string, Mandi> _mandiByCode = [];

    public IngestionRecordWriterBatchTests()
    {
        _categories.GetSubCategoryIdsAsync(_categoryId, Arg.Any<CancellationToken>())
            .Returns((IReadOnlySet<Guid>)new HashSet<Guid> { _subCategoryId });
        _onion = Product.Create(
            CatalogCode.Create("onion").Value,
            _subCategoryId,
            Guid.CreateVersion7(),
            1,
            null,
            [CatalogTranslation.Create(LanguageCode.English, "Onion").Value]).Value;
        _products.GetByCodeAsync(Arg.Is<CatalogCode>(c => c.Value == "onion"), Arg.Any<CancellationToken>()).Returns(_onion);

        // Every market code resolves to its own mandi, created on first use.
        _mandis.GetByCodeAsync(Arg.Any<MarketCode>(), Arg.Any<CancellationToken>()).Returns(call =>
        {
            var code = call.Arg<MarketCode>();
            if (!_mandiByCode.TryGetValue(code.Value, out var mandi))
            {
                mandi = Mandi.Create(code, Guid.CreateVersion7(), code.Value).Value;
                _mandiByCode[code.Value] = mandi;
            }

            return mandi;
        });
        _records.GetActiveForDaysAsync(Arg.Any<Guid>(), Arg.Any<IReadOnlyCollection<DateOnly>>(), Arg.Any<CancellationToken>())
            .Returns((IReadOnlyList<PriceRecord>)[]);
    }

    private IngestionRecordWriter CreateWriter() =>
        new(_errors, _records, _products, _categories, _mandis, Substitute.For<ISupplierRepository>(), new FixedTimeProvider(Now));

    private static IngestedPriceRecord Row(string location, decimal modal = 2000m) =>
        new("onion", null, LocationKind.Mandi, location, null, null, modal, null, Day);

    private static IngestedPriceRecord[] Rows(int count) =>
        [.. Enumerable.Range(0, count).Select(i => Row($"market-{i}"))];

    [Fact]
    public async Task A_big_batch_looks_each_product_and_market_up_once_and_never_per_row()
    {
        var counts = await CreateWriter().WriteAsync(
            _job, _categoryId, [.. Rows(250), .. Rows(250).Select(r => r with { ModalPrice = 2100m })],
            CancellationToken.None, skipRowsOutsideCatalog: true);

        // The second 250 repeat the first 250's product/market/day, so they are source duplicates, not new rows.
        Assert.Equal(250, counts.Persisted);
        Assert.Equal(250, counts.Failed + counts.Skipped);

        await _products.Received(1).GetByCodeAsync(Arg.Any<CatalogCode>(), Arg.Any<CancellationToken>());
        await _mandis.Received(250).GetByCodeAsync(Arg.Any<MarketCode>(), Arg.Any<CancellationToken>());
        await _records.Received(1).GetActiveForDaysAsync(_job.PriceSourceId, Arg.Any<IReadOnlyCollection<DateOnly>>(), Arg.Any<CancellationToken>());
        await _records.DidNotReceiveWithAnyArgs().FindActiveAsync(default, default, default, default, default, default, default, default, default);
    }

    [Fact]
    public async Task A_live_record_found_in_the_preload_is_unchanged_when_the_figures_match()
    {
        var rows = Rows(250);
        // The mandi for market-0 exists already, with the same price stored earlier.
        var first = (await _mandis.GetByCodeAsync(MarketCode.Create("market-0").Value))!;
        var existing = PriceRecord.Create(
            _onion.Id, null, _onion.DefaultUnitId, LocationKind.Mandi, first.Id, null, _job.PriceSourceId, null, null, 2000m, null, Day).Value;
        _records.GetActiveForDaysAsync(Arg.Any<Guid>(), Arg.Any<IReadOnlyCollection<DateOnly>>(), Arg.Any<CancellationToken>())
            .Returns((IReadOnlyList<PriceRecord>)[existing]);

        var counts = await CreateWriter().WriteAsync(_job, _categoryId, rows, CancellationToken.None, skipRowsOutsideCatalog: true);

        Assert.Equal(1, counts.Unchanged);
        Assert.Equal(249, counts.Persisted);
        Assert.False(existing.IsVoided);
    }

    [Fact]
    public async Task A_corrected_price_voids_the_preloaded_record_and_stores_a_new_one()
    {
        var rows = Rows(250);
        rows[0] = rows[0] with { ModalPrice = 2500m };
        var first = (await _mandis.GetByCodeAsync(MarketCode.Create("market-0").Value))!;
        var existing = PriceRecord.Create(
            _onion.Id, null, _onion.DefaultUnitId, LocationKind.Mandi, first.Id, null, _job.PriceSourceId, null, null, 2000m, null, Day).Value;
        _records.GetActiveForDaysAsync(Arg.Any<Guid>(), Arg.Any<IReadOnlyCollection<DateOnly>>(), Arg.Any<CancellationToken>())
            .Returns((IReadOnlyList<PriceRecord>)[existing]);

        var counts = await CreateWriter().WriteAsync(_job, _categoryId, rows, CancellationToken.None, skipRowsOutsideCatalog: true);

        Assert.Equal(250, counts.Persisted);
        Assert.True(existing.IsVoided);
    }

    [Fact]
    public async Task A_small_batch_still_checks_each_row_so_uploads_keep_working()
    {
        await CreateWriter().WriteAsync(_job, _categoryId, Rows(5), CancellationToken.None);

        await _records.DidNotReceiveWithAnyArgs().GetActiveForDaysAsync(default, default!, default);
        await _records.ReceivedWithAnyArgs(5).FindActiveAsync(default, default, default, default, default, default, default, default, default);
    }
}
