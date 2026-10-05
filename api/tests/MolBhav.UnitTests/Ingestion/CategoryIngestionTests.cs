using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Ingestion.Admin.RunCategoryIngestion;
using MolBhav.Application.Features.Pricing.Admin.CreatePriceSource;
using MolBhav.Application.Features.Pricing.Admin.UpdatePriceSource;
using MolBhav.Domain.Pricing;
using MolBhav.Domain.SharedKernel;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Ingestion;

public sealed class CategoryIngestionTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 4, 6, 0, 0, TimeSpan.Zero); // 11:30 IST
    private static readonly DateOnly IstToday = new(2026, 10, 4);

    private readonly IProcurementCategoryRepository _categories = Substitute.For<IProcurementCategoryRepository>();
    private readonly IPriceSourceRepository _sources = Substitute.For<IPriceSourceRepository>();
    private readonly IIngestionBackfillQueue _queue = Substitute.For<IIngestionBackfillQueue>();
    private readonly Guid _construction = Guid.CreateVersion7();
    private readonly Guid _admin = Guid.CreateVersion7();

    public CategoryIngestionTests()
    {
        _categories.GetActiveIdByCodeAsync(Arg.Is<ProcurementCategoryCode>(c => c.Value == "construction"), Arg.Any<CancellationToken>())
            .Returns((Guid?)_construction);
        _queue.TryEnqueue(Arg.Any<IngestionBackfillRequest>()).Returns(true);
    }

    private RunCategoryIngestionCommandHandler RunHandler() => new(_categories, _sources, _queue, new FixedTimeProvider(Now));

    [Fact]
    public void PriceSource_RequiresACategory()
    {
        Assert.Equal("PriceSource.CategoryRequired", PriceSource.Create("cpwd-dsr", "CPWD DSR", Guid.Empty).Error.Code);

        var source = PriceSource.Create("cpwd-dsr", "CPWD DSR", _construction).Value;
        Assert.Equal(_construction, source.CategoryId);
        Assert.Equal("PriceSource.CategoryRequired", source.Update("CPWD DSR", true, Guid.Empty).Error.Code);
    }

    [Fact]
    public async Task CreateSource_UnknownCategory_IsRejected()
    {
        var handler = new CreatePriceSourceCommandHandler(_sources, _categories);

        var result = await handler.Handle(new CreatePriceSourceCommand("tiles-feed", "Tiles feed", "interiors"), CancellationToken.None);

        Assert.Equal("PriceSource.CategoryNotFound", result.Error.Code);
        _sources.DidNotReceive().Add(Arg.Any<PriceSource>());
    }

    [Fact]
    public async Task CreateSource_StoresTheCategory()
    {
        PriceSource? added = null;
        _sources.When(s => s.Add(Arg.Any<PriceSource>())).Do(call => added = call.Arg<PriceSource>());
        var handler = new CreatePriceSourceCommandHandler(_sources, _categories);

        var result = await handler.Handle(new CreatePriceSourceCommand("cpwd-dsr", "CPWD DSR", "Construction"), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.NotNull(added);
        Assert.Equal(_construction, added.CategoryId);
    }

    [Fact]
    public async Task UpdateSource_MovesItToAnotherCategory()
    {
        var source = PriceSource.Create("supplier-quotes", "Supplier quotes", Guid.CreateVersion7()).Value;
        _sources.GetByIdAsync(source.Id, Arg.Any<CancellationToken>()).Returns(source);
        var handler = new UpdatePriceSourceCommandHandler(_sources, _categories);

        var result = await handler.Handle(new UpdatePriceSourceCommand(source.Id, "Supplier quotes", true, "construction"), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(_construction, source.CategoryId);
    }

    [Fact]
    public async Task RunCategory_QueuesEveryActiveSourceForTheDefaultDay()
    {
        Guid[] ids = [Guid.CreateVersion7(), Guid.CreateVersion7()];
        _sources.GetActiveIdsByCategoryAsync(_construction, Arg.Any<CancellationToken>()).Returns(ids);

        var result = await RunHandler().Handle(new RunCategoryIngestionCommand("construction", _admin), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(2, result.Value.Sources);
        Assert.Equal(IstToday.AddDays(-1), result.Value.AsOfDate);
        _queue.Received(1).TryEnqueue(Arg.Is<IngestionBackfillRequest>(r =>
            r.PriceSourceIds.SequenceEqual(ids) && r.RequestedByUserId == _admin && r.Dates.SequenceEqual(new[] { IstToday.AddDays(-1) })));
    }

    [Fact]
    public async Task RunCategory_NoActiveSources_IsRejected()
    {
        _sources.GetActiveIdsByCategoryAsync(_construction, Arg.Any<CancellationToken>()).Returns(Array.Empty<Guid>());

        var result = await RunHandler().Handle(new RunCategoryIngestionCommand("construction", _admin), CancellationToken.None);

        Assert.Equal("Ingestion.NoActiveSources", result.Error.Code);
        _queue.DidNotReceive().TryEnqueue(Arg.Any<IngestionBackfillRequest>());
    }

    [Fact]
    public async Task RunCategory_UnknownCategoryOrFutureDate_IsRejected()
    {
        var unknown = await RunHandler().Handle(new RunCategoryIngestionCommand("interiors", _admin), CancellationToken.None);
        var future = await RunHandler().Handle(new RunCategoryIngestionCommand("construction", _admin, IstToday.AddDays(1)), CancellationToken.None);

        Assert.Equal("Category.NotFound", unknown.Error.Code);
        Assert.Equal("Ingestion.FutureDate", future.Error.Code);
    }
}
