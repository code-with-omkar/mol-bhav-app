using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Catalog.Admin.ImportFeedProducts;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Pricing;

namespace MolBhav.UnitTests.Ingestion;

public sealed class ImportFeedProductsTests
{
    private static readonly DateTimeOffset Now = new(2026, 11, 1, 6, 0, 0, TimeSpan.Zero);

    private readonly IPriceSourceRepository _sources = Substitute.For<IPriceSourceRepository>();
    private readonly ISourceFeedOptionsRepository _feedOptions = Substitute.For<ISourceFeedOptionsRepository>();
    private readonly IProductRepository _products = Substitute.For<IProductRepository>();
    private readonly IProcurementCategoryRepository _categories = Substitute.For<IProcurementCategoryRepository>();
    private readonly IUnitOfMeasureRepository _units = Substitute.For<IUnitOfMeasureRepository>();
    private readonly IFeedMarketCodes _codes = Substitute.For<IFeedMarketCodes>();
    private readonly PriceSource _source = PriceSource.Create("agmarknet", "Agmarknet", Guid.CreateVersion7()).Value;
    private readonly Guid _subCategoryId = Guid.CreateVersion7();
    private readonly Guid _unitId = Guid.CreateVersion7();
    private readonly ImportFeedProductsCommandHandler _handler;

    public ImportFeedProductsTests()
    {
        _sources.GetByIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns(_source);
        _categories.SubCategoryExistsAsync(_subCategoryId, Arg.Any<CancellationToken>()).Returns(true);
        _units.ExistsAsync(_unitId, Arg.Any<CancellationToken>()).Returns(true);
        _products.CodeExistsAsync(Arg.Any<CatalogCode>(), Arg.Any<CancellationToken>()).Returns(false);
        // The same slug rule ingestion uses, without the config map.
        _codes.ProductCodeFor(Arg.Any<string>()).Returns(call => new string(
            call.Arg<string>().ToLowerInvariant().Select(c => char.IsLetterOrDigit(c) ? c : '-').ToArray()).Trim('-'));
        _handler = new ImportFeedProductsCommandHandler(_sources, _feedOptions, _products, _categories, _units, _codes);
        WithFeed("Onion", "Tomato", "Red Onion", "123 Bad");
    }

    private void WithFeed(params string[] commodities) =>
        _feedOptions.GetByPriceSourceIdAsync(_source.Id, Arg.Any<CancellationToken>())
            .Returns(SourceFeedOptions.Create(_source.Id, commodities, [], Now).Value);

    private Task<MolBhav.Domain.Common.Results.Result<ImportFeedProductsResponse>> Import(params string[] commodities) =>
        _handler.Handle(new ImportFeedProductsCommand(_source.Id, _subCategoryId, _unitId, commodities), CancellationToken.None);

    [Fact]
    public async Task Commodities_are_added_with_the_code_ingestion_uses_and_the_feed_name()
    {
        var result = await Import("Onion", "Red Onion");

        Assert.True(result.IsSuccess);
        Assert.Equal(2, result.Value.Created);
        Assert.Empty(result.Value.Skipped);
        _products.Received(1).Add(Arg.Is<Product>(p =>
            p.Code.Value == "onion" && p.SubCategoryId == _subCategoryId && p.DefaultUnitId == _unitId));
        _products.Received(1).Add(Arg.Is<Product>(p => p.Code.Value == "red-onion"));
    }

    [Fact]
    public async Task A_product_that_already_exists_is_skipped_not_duplicated()
    {
        _products.CodeExistsAsync(Arg.Is<CatalogCode>(c => c.Value == "onion"), Arg.Any<CancellationToken>()).Returns(true);

        var result = await Import("Onion", "Tomato");

        Assert.Equal(1, result.Value.Created);
        Assert.Equal(new SkippedFeedCommodity("Onion", FeedCommoditySkipReason.AlreadyInCatalog), Assert.Single(result.Value.Skipped));
    }

    [Fact]
    public async Task A_commodity_not_in_the_feed_list_is_skipped()
    {
        var result = await Import("Nowhere");

        Assert.Equal(0, result.Value.Created);
        Assert.Equal(FeedCommoditySkipReason.NotInFeed, Assert.Single(result.Value.Skipped).Reason);
        _products.DidNotReceive().Add(Arg.Any<Product>());
    }

    [Fact]
    public async Task A_name_that_cannot_make_a_code_is_skipped()
    {
        var result = await Import("123 Bad");

        Assert.Equal(FeedCommoditySkipReason.CodeInvalid, Assert.Single(result.Value.Skipped).Reason);
    }

    [Fact]
    public async Task Names_match_the_feed_list_whatever_their_case_and_repeats_count_once()
    {
        var result = await Import("onion", "ONION");

        Assert.Equal(1, result.Value.Created);
        Assert.Empty(result.Value.Skipped);
    }

    [Fact]
    public async Task Two_spellings_that_resolve_to_one_code_add_one_product()
    {
        WithFeed("Onion", "Onion!");

        var result = await Import("Onion", "Onion!");

        Assert.Equal(1, result.Value.Created);
        Assert.Equal(FeedCommoditySkipReason.AlreadyInCatalog, Assert.Single(result.Value.Skipped).Reason);
    }

    [Fact]
    public async Task An_unknown_sub_category_is_refused()
    {
        _categories.SubCategoryExistsAsync(_subCategoryId, Arg.Any<CancellationToken>()).Returns(false);

        var result = await Import("Onion");

        Assert.True(result.IsFailure);
        Assert.Equal("SubCategory.NotFound", result.Error.Code);
    }

    [Fact]
    public async Task An_unknown_unit_is_refused()
    {
        _units.ExistsAsync(_unitId, Arg.Any<CancellationToken>()).Returns(false);

        var result = await Import("Onion");

        Assert.Equal("UnitOfMeasure.NotFound", result.Error.Code);
    }

    [Fact]
    public async Task A_source_with_no_saved_feed_list_is_refused_with_guidance()
    {
        WithFeed();

        var result = await Import("Onion");

        Assert.Equal("FeedProducts.NoFeedList", result.Error.Code);
    }

    [Fact]
    public async Task An_unknown_source_is_not_found()
    {
        var result = await _handler.Handle(
            new ImportFeedProductsCommand(Guid.CreateVersion7(), _subCategoryId, _unitId, ["Onion"]), CancellationToken.None);

        Assert.Equal("PriceSource.NotFound", result.Error.Code);
    }

    [Fact]
    public void Validation_needs_at_least_one_commodity_and_caps_the_batch()
    {
        var validator = new ImportFeedProductsCommandValidator();

        Assert.False(validator.Validate(new ImportFeedProductsCommand(_source.Id, _subCategoryId, _unitId, [])).IsValid);
        Assert.False(validator.Validate(new ImportFeedProductsCommand(_source.Id, _subCategoryId, _unitId, null)).IsValid);
        Assert.False(validator.Validate(new ImportFeedProductsCommand(
            _source.Id, _subCategoryId, _unitId, Enumerable.Range(0, 201).Select(i => $"C{i}").ToArray())).IsValid);
        Assert.True(validator.Validate(new ImportFeedProductsCommand(_source.Id, _subCategoryId, _unitId, ["Onion"])).IsValid);
    }
}
