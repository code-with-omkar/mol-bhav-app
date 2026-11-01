using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Ingestion.Admin.GetSourceFeedOptions;
using MolBhav.Application.Features.Ingestion.Admin.RunIngestionJob;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Application.Features.Ingestion.Common;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Pricing;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Ingestion;

public sealed class IngestionFilterTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 16, 3, 30, 0, TimeSpan.Zero);

    [Fact]
    public void Names_are_trimmed_deduplicated_ignoring_case_and_blanks_dropped()
    {
        var filter = IngestionFilter.Create(["  Maharashtra ", "maharashtra", "", "Goa"], null, [" "]).Value;

        Assert.Equal(["Maharashtra", "Goa"], filter.States);
        Assert.Empty(filter.Markets);
        Assert.False(filter.IsEmpty);
    }

    [Fact]
    public void Nothing_means_everything()
    {
        Assert.True(IngestionFilter.Create(null, null, null).Value.IsEmpty);
        Assert.Equal(1, IngestionFilter.Empty.Combinations);
    }

    [Fact]
    public void Combinations_multiply_the_non_empty_lists()
    {
        Assert.Equal(6, IngestionFilter.Create(["A", "B"], ["X", "Y", "Z"], null).Value.Combinations);
    }

    [Fact]
    public void Too_many_combinations_are_refused()
    {
        var result = IngestionFilter.Create(
            Enumerable.Range(1, 6).Select(i => $"S{i}"), Enumerable.Range(1, 6).Select(i => $"C{i}"), ["M"]);

        Assert.Equal("IngestionFilter.TooBroad", result.Error.Code);
    }

    [Fact]
    public void Too_many_or_too_long_names_are_refused()
    {
        Assert.Equal(
            "IngestionFilter.TooManyNames",
            IngestionFilter.Create(null, Enumerable.Range(1, 21).Select(i => $"C{i}"), null).Error.Code);
        Assert.Equal("IngestionFilter.NameTooLong", IngestionFilter.Create([new string('x', 101)], null, null).Error.Code);
    }

    [Fact]
    public void Equal_filters_compare_equal_regardless_of_case()
    {
        Assert.Equal(IngestionFilter.Create(["Goa"], null, null).Value, IngestionFilter.Create(["GOA"], null, null).Value);
        Assert.NotEqual(IngestionFilter.Create(["Goa"], null, null).Value, IngestionFilter.Empty);
    }

    // --- the run handler: a manual run's filter reaches the adapter; scheduled runs pull everything ---

    private readonly IDataIngestionJobRepository _jobs = Substitute.For<IDataIngestionJobRepository>();
    private readonly IPriceSourceRepository _sources = Substitute.For<IPriceSourceRepository>();
    private readonly IIngestionSourceAdapter _adapter = Substitute.For<IIngestionSourceAdapter>();
    private readonly ISourceFeedOptionsRepository _feedOptions = Substitute.For<ISourceFeedOptionsRepository>();
    private readonly PriceSource _source = PriceSource.Create("agmarknet", "Agmarknet", Guid.CreateVersion7()).Value;
    private IngestionFetchRequest? _requested;

    private RunIngestionJobCommandHandler CreateRunHandler()
    {
        _sources.GetByIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns(_source);
        _adapter.FetchAsync(Arg.Do<IngestionFetchRequest>(r => _requested = r), Arg.Any<CancellationToken>())
            .Returns(IngestionFetchResult.Success([]));
        var time = new FixedTimeProvider(Now);
        var writer = new IngestionRecordWriter(
            Substitute.For<IDataIngestionErrorRepository>(),
            Substitute.For<IPriceRecordRepository>(),
            Substitute.For<IProductRepository>(),
            Substitute.For<IProcurementCategoryRepository>(),
            Substitute.For<IMandiRepository>(),
            Substitute.For<ISupplierRepository>(),
            time);
        return new RunIngestionJobCommandHandler(
            _jobs, _sources, _feedOptions, _adapter, writer, time, Microsoft.Extensions.Logging.Abstractions.NullLogger<RunIngestionJobCommandHandler>.Instance);
    }

    [Fact]
    public async Task A_manual_runs_filter_is_passed_to_the_adapter()
    {
        var result = await CreateRunHandler().Handle(
            new(_source.Id, IngestionTriggerType.Manual, Guid.CreateVersion7(), null, ["Maharashtra"], ["Onion"], null), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(["Maharashtra"], _requested!.Filter!.States);
        Assert.Equal(["Onion"], _requested.Filter.Commodities);
        Assert.Empty(_requested.Filter.Markets);
    }

    [Fact]
    public async Task A_scheduled_run_with_no_filter_pulls_everything()
    {
        await CreateRunHandler().Handle(new(_source.Id, IngestionTriggerType.Scheduled, null), CancellationToken.None);

        Assert.True(_requested!.Filter!.IsEmpty);
    }

    // --- feed names: a full pull saves what the feed contains; the filter dropdowns read it ---

    private static FeedNames Names() =>
        new(["Onion", "Tomato"], [new FeedMarket("APMC Pune", "Maharashtra"), new FeedMarket("Indore", "Madhya Pradesh")]);

    [Fact]
    public async Task A_full_pull_saves_the_names_it_saw()
    {
        var handler = CreateRunHandler();
        _adapter.FetchAsync(Arg.Any<IngestionFetchRequest>(), Arg.Any<CancellationToken>()).Returns(IngestionFetchResult.Success([], Names()));
        _feedOptions.GetByPriceSourceIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns((SourceFeedOptions?)null);

        await handler.Handle(new(_source.Id, IngestionTriggerType.Scheduled, null), CancellationToken.None);

        _feedOptions.Received(1).Add(Arg.Is<SourceFeedOptions>(o =>
            o.PriceSourceId == _source.Id
            && o.Commodities.SequenceEqual(new[] { "Onion", "Tomato" })
            && o.States.SequenceEqual(new[] { "Madhya Pradesh", "Maharashtra" })));
    }

    [Fact]
    public async Task A_later_full_pull_replaces_the_saved_names()
    {
        var handler = CreateRunHandler();
        _adapter.FetchAsync(Arg.Any<IngestionFetchRequest>(), Arg.Any<CancellationToken>()).Returns(IngestionFetchResult.Success([], Names()));
        var existing = SourceFeedOptions.Create(_source.Id, ["Old"], [new FeedMarket("Old Market", "Goa")], Now.AddDays(-1)).Value;
        _feedOptions.GetByPriceSourceIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns(existing);

        await handler.Handle(new(_source.Id, IngestionTriggerType.Scheduled, null), CancellationToken.None);

        Assert.Equal(["Onion", "Tomato"], existing.Commodities);
        Assert.Equal(Now, existing.RefreshedAtUtc);
        _feedOptions.DidNotReceiveWithAnyArgs().Add(default!);
    }

    [Fact]
    public async Task A_run_that_saw_no_names_leaves_the_saved_ones_alone()
    {
        // A filtered pull sees only a slice: the adapter returns no names, so nothing is saved or replaced.
        await CreateRunHandler().Handle(
            new(_source.Id, IngestionTriggerType.Manual, Guid.CreateVersion7(), null, ["Maharashtra"]), CancellationToken.None);

        _feedOptions.DidNotReceiveWithAnyArgs().Add(default!);
        await _feedOptions.DidNotReceiveWithAnyArgs().GetByPriceSourceIdAsync(default, default);
    }

    [Fact]
    public void Saved_names_are_cleaned_sorted_and_states_come_from_the_markets()
    {
        var options = SourceFeedOptions.Create(
            _source.Id,
            [" Tomato ", "onion", "ONION", ""],
            [new("Z Market", "Goa"), new(" APMC Pune ", "Maharashtra"), new("apmc pune", "MAHARASHTRA"), new("", "Goa"), new("No State", "")],
            Now).Value;

        Assert.Equal(["onion", "Tomato"], options.Commodities);
        Assert.Equal(["APMC Pune", "Z Market"], options.Markets.Select(m => m.Name).ToArray().Order().ToArray());
        Assert.Equal(["Goa", "Maharashtra"], options.States);
        Assert.Equal(2, options.Markets.Count);
    }

    [Fact]
    public async Task The_options_query_returns_empty_until_a_full_pull_has_run_and_404_for_an_unknown_source()
    {
        _sources.GetByIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns(_source);
        var handler = new GetSourceFeedOptionsQueryHandler(_sources, _feedOptions);

        var none = await handler.Handle(new(_source.Id), CancellationToken.None);
        var unknown = await handler.Handle(new(Guid.CreateVersion7()), CancellationToken.None);

        Assert.Empty(none.Value.States);
        Assert.Null(none.Value.RefreshedAtUtc);
        Assert.Equal("PriceSource.NotFound", unknown.Error.Code);

        _feedOptions.GetByPriceSourceIdAsync(_source.Id, Arg.Any<CancellationToken>())
            .Returns(SourceFeedOptions.Create(_source.Id, ["Onion"], [new FeedMarket("APMC Pune", "Maharashtra")], Now).Value);
        var saved = (await handler.Handle(new(_source.Id), CancellationToken.None)).Value;

        Assert.Equal(["Maharashtra"], saved.States);
        Assert.Equal(["Onion"], saved.Commodities);
        Assert.Equal(new FeedMarketResponse("APMC Pune", "Maharashtra"), Assert.Single(saved.Markets));
        Assert.Equal(Now, saved.RefreshedAtUtc);
    }

    [Fact]
    public async Task A_bad_filter_is_refused_before_any_job_is_created()
    {
        var tooBroad = Enumerable.Range(1, 10).Select(i => $"S{i}").ToArray();

        var result = await CreateRunHandler().Handle(
            new(_source.Id, IngestionTriggerType.Manual, Guid.CreateVersion7(), null, tooBroad, tooBroad, null), CancellationToken.None);

        Assert.Equal("IngestionFilter.TooBroad", result.Error.Code);
        _jobs.DidNotReceiveWithAnyArgs().Add(default!);
        Assert.Null(_requested);
    }
}
