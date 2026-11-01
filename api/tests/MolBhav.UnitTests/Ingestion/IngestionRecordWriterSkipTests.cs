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

/// <summary>A national feed (Agmarknet) is mostly products/markets the app does not track; adapter runs skip those instead of storing them as errors.</summary>
public sealed class IngestionRecordWriterSkipTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 15, 6, 0, 0, TimeSpan.Zero);
    private static readonly DateOnly Day = new(2026, 10, 15);

    private readonly IDataIngestionErrorRepository _errors = Substitute.For<IDataIngestionErrorRepository>();
    private readonly IProductRepository _products = Substitute.For<IProductRepository>();
    private readonly IProcurementCategoryRepository _categories = Substitute.For<IProcurementCategoryRepository>();
    private readonly IMandiRepository _mandis = Substitute.For<IMandiRepository>();
    private readonly Guid _categoryId = Guid.CreateVersion7();
    private readonly Guid _subCategoryId = Guid.CreateVersion7();
    private readonly DataIngestionJob _job = DataIngestionJob.Start(Guid.CreateVersion7(), IngestionTriggerType.Scheduled, null, Day, Now).Value;

    public IngestionRecordWriterSkipTests()
    {
        _categories.GetSubCategoryIdsAsync(_categoryId, Arg.Any<CancellationToken>())
            .Returns((IReadOnlySet<Guid>)new HashSet<Guid> { _subCategoryId });

        // Only "onion" is in the catalog; no mandi is.
        _onion = Product.Create(
            CatalogCode.Create("onion").Value,
            _subCategoryId,
            Guid.CreateVersion7(),
            1,
            null,
            [CatalogTranslation.Create(LanguageCode.English, "Onion").Value]).Value;
        _products.GetByCodeAsync(Arg.Is<CatalogCode>(c => c.Value == "onion"), Arg.Any<CancellationToken>()).Returns(_onion);
    }

    private readonly IPriceRecordRepository _records = Substitute.For<IPriceRecordRepository>();
    private readonly List<PriceRecord> _stored = [];
    private Product _onion = null!;

    private IngestionRecordWriter CreateWriter()
    {
        _records.When(r => r.Add(Arg.Any<PriceRecord>())).Do(call => _stored.Add(call.Arg<PriceRecord>()));
        return new(_errors, _records, _products, _categories, _mandis, Substitute.For<ISupplierRepository>(), new FixedTimeProvider(Now));
    }

    private static IngestedPriceRecord Row(string product, string location, string? variant = null, decimal modal = 2000m) =>
        new(product, variant, LocationKind.Mandi, location, null, null, modal, null, Day);

    /// <summary>Makes "apmc-pune" a tracked mandi so rows can get as far as being stored.</summary>
    private void TrackPune() =>
        _mandis.GetByCodeAsync(Arg.Is<MarketCode>(c => c.Value == "apmc-pune"), Arg.Any<CancellationToken>())
            .Returns(Mandi.Create(MarketCode.Create("apmc-pune").Value, Guid.CreateVersion7(), "APMC Pune").Value);

    [Fact]
    public async Task Unknown_product_is_skipped_not_recorded_when_skipping()
    {
        var counts = await CreateWriter().WriteAsync(_job, _categoryId, [Row("dragon-fruit", "apmc-pune")], CancellationToken.None, skipRowsOutsideCatalog: true);

        Assert.Equal(new IngestionWriteCounts(0, 0, 0, 0, 1), counts);
        _errors.DidNotReceiveWithAnyArgs().Add(default!);
    }

    [Fact]
    public async Task Unknown_product_is_still_an_error_for_uploads()
    {
        var counts = await CreateWriter().WriteAsync(_job, _categoryId, [Row("dragon-fruit", "apmc-pune")], CancellationToken.None);

        Assert.Equal(new IngestionWriteCounts(1, 0, 0, 1, 0), counts);
        _errors.Received(1).Add(Arg.Is<DataIngestionError>(e => e.ErrorMessage.Contains("dragon-fruit", StringComparison.Ordinal)));
    }

    [Fact]
    public async Task Names_that_cannot_be_codes_are_skipped_but_keep_their_message_for_uploads()
    {
        var rows = new[] { Row("2-wheeler", "apmc-pune"), Row("onion", "9th-street-market") };

        var skipped = await CreateWriter().WriteAsync(_job, _categoryId, rows, CancellationToken.None, skipRowsOutsideCatalog: true);
        Assert.Equal(2, skipped.Skipped);
        Assert.Equal(0, skipped.Failed);

        var upload = await CreateWriter().WriteAsync(_job, _categoryId, rows, CancellationToken.None);
        Assert.Equal(2, upload.Failed);
        _errors.Received(2).Add(Arg.Is<DataIngestionError>(e => e.ErrorMessage.StartsWith("Code must start with a letter", StringComparison.Ordinal)));
    }

    [Fact]
    public async Task Catalog_product_in_an_untracked_mandi_is_skipped()
    {
        var counts = await CreateWriter().WriteAsync(_job, _categoryId, [Row("onion", "apmc-baripada")], CancellationToken.None, skipRowsOutsideCatalog: true);

        Assert.Equal(new IngestionWriteCounts(0, 0, 0, 0, 1), counts);
        _errors.DidNotReceiveWithAnyArgs().Add(default!);
    }

    [Fact]
    public async Task Unknown_variety_of_a_catalog_product_is_still_an_error_when_skipping()
    {
        // The product and mandi are ours, only the variety is missing: an actionable gap, not noise.
        var counts = await CreateWriter().WriteAsync(_job, _categoryId, [Row("onion", "apmc-pune", variant: "local")], CancellationToken.None, skipRowsOutsideCatalog: true);

        Assert.Equal(new IngestionWriteCounts(1, 0, 0, 1, 0), counts);
        _errors.Received(1).Add(Arg.Is<DataIngestionError>(e => e.ErrorMessage.Contains("No active variant 'local'", StringComparison.Ordinal)));
    }

    private Task<IngestionWriteCounts> WriteFeedAsync(params IngestedPriceRecord[] rows) =>
        CreateWriter().WriteAsync(_job, _categoryId, rows, CancellationToken.None, skipRowsOutsideCatalog: true, fallbackToProductForUnknownVariety: true);

    [Fact]
    public async Task Unknown_variety_is_stored_as_the_products_no_variant_price()
    {
        TrackPune();

        var counts = await WriteFeedAsync(Row("onion", "apmc-pune", variant: "local", modal: 2100m));

        Assert.Equal(new IngestionWriteCounts(1, 1, 0, 0, 0), counts);
        var record = Assert.Single(_stored);
        Assert.Null(record.VariantId);
        Assert.Equal(2100m, record.ModalPrice);
        _errors.DidNotReceiveWithAnyArgs().Add(default!);
    }

    [Fact]
    public async Task A_variety_that_cannot_be_a_code_also_falls_back()
    {
        TrackPune();

        var counts = await WriteFeedAsync(Row("onion", "apmc-pune", variant: "1st-sort"));

        Assert.Equal(1, counts.Persisted);
        Assert.Equal(0, counts.Failed);
        Assert.Null(Assert.Single(_stored).VariantId);
    }

    [Fact]
    public async Task A_catalog_variety_is_still_used_when_it_matches()
    {
        TrackPune();
        var red = _onion.AddVariant(CatalogCode.Create("red").Value, 1, [CatalogTranslation.Create(LanguageCode.English, "Red").Value]).Value;

        await WriteFeedAsync(Row("onion", "apmc-pune", variant: "red"));

        Assert.Equal(red.Id, Assert.Single(_stored).VariantId);
    }

    [Fact]
    public async Task A_generic_row_wins_over_an_unknown_variety_that_came_first()
    {
        TrackPune();

        var counts = await WriteFeedAsync(
            Row("onion", "apmc-pune", variant: "local", modal: 1111m),
            Row("onion", "apmc-pune", modal: 2222m));

        Assert.Equal(new IngestionWriteCounts(1, 1, 0, 0, 1), counts);
        Assert.Equal(2222m, Assert.Single(_stored).ModalPrice);
    }

    [Fact]
    public async Task Several_unknown_varieties_collapse_into_one_price_without_duplicate_errors()
    {
        TrackPune();

        var counts = await WriteFeedAsync(
            Row("onion", "apmc-pune", variant: "local", modal: 1111m),
            Row("onion", "apmc-pune", variant: "hybrid", modal: 3333m));

        Assert.Equal(new IngestionWriteCounts(1, 1, 0, 0, 1), counts);
        Assert.Equal(1111m, Assert.Single(_stored).ModalPrice); // first one kept
        _errors.DidNotReceiveWithAnyArgs().Add(default!);
    }

    [Fact]
    public async Task Unknown_variety_in_an_untracked_mandi_is_skipped_not_stored()
    {
        // No mandi is tracked here: the variety fallback must not turn an out-of-catalog row into a record.
        var counts = await WriteFeedAsync(Row("onion", "apmc-baripada", variant: "local"));

        Assert.Equal(new IngestionWriteCounts(0, 0, 0, 0, 1), counts);
        Assert.Empty(_stored);
    }

    [Fact]
    public async Task Without_the_fallback_an_unknown_variety_still_fails()
    {
        TrackPune();

        var counts = await CreateWriter().WriteAsync(
            _job, _categoryId, [Row("onion", "apmc-pune", variant: "local")], CancellationToken.None, skipRowsOutsideCatalog: true);

        Assert.Equal(new IngestionWriteCounts(1, 0, 0, 1, 0), counts);
        Assert.Empty(_stored);
    }

    [Fact]
    public async Task Fetched_counts_only_rows_inside_the_catalog()
    {
        var rows = new[] { Row("dragon-fruit", "apmc-pune"), Row("jackfruit", "apmc-pune"), Row("onion", "apmc-pune", variant: "local") };

        var counts = await CreateWriter().WriteAsync(_job, _categoryId, rows, CancellationToken.None, skipRowsOutsideCatalog: true);

        Assert.Equal(2, counts.Skipped);
        Assert.Equal(1, counts.Fetched);
        Assert.Equal(counts.Fetched, counts.Persisted + counts.Unchanged + counts.Failed);
    }
}
