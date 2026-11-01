using MolBhav.Application.Abstractions.Admin;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Features.Admin.GetAdminDashboard;
using MolBhav.Application.Features.Admin.Models;
using MolBhav.Domain.Ingestion;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Admin;

public sealed class GetAdminDashboardQueryHandlerTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 17, 6, 30, 0, TimeSpan.Zero); // 12:00 IST, 17 Oct

    private readonly IAdminDashboardReadService _counts = Substitute.For<IAdminDashboardReadService>();
    private readonly IIngestionReadService _ingestion = Substitute.For<IIngestionReadService>();

    private static readonly DashboardCounts Counts = new(
        new AdminUsersSummary(10, 3, 6, 1, 4, 6),
        new AdminAdsSummary(500, 20, 3000, 90, 3.0, 2, 14),
        new AdminSupportSummary(5));

    private async Task<AdminDashboardResponse> RunAsync(params FeedHealth[] feeds)
    {
        _counts.GetCountsAsync(Arg.Any<DateOnly>(), Arg.Any<DateTimeOffset>(), Arg.Any<CancellationToken>()).Returns(Counts);
        _ingestion.GetScheduledFeedHealthAsync(Arg.Any<CancellationToken>()).Returns(feeds);

        var result = await new GetAdminDashboardQueryHandler(_counts, _ingestion, new FixedTimeProvider(Now))
            .Handle(new GetAdminDashboardQuery(), CancellationToken.None);

        Assert.True(result.IsSuccess);
        return result.Value;
    }

    private static FeedHealth Feed(TimeSpan? successAgo, IngestionJobStatus? last = IngestionJobStatus.Succeeded) =>
        new(Guid.CreateVersion7(), "agmarknet", successAgo is { } a ? Now - a : null, last, last is null ? null : Now - TimeSpan.FromMinutes(10));

    [Fact]
    public async Task Counts_pass_through_and_today_is_the_IST_day()
    {
        var response = await RunAsync(Feed(TimeSpan.FromHours(2)));

        Assert.Equal(Counts.Users, response.Users);
        Assert.Equal(Counts.Ads, response.Ads);
        Assert.Equal(5, response.Support.OpenTickets);
        Assert.Equal(Now, response.GeneratedAtUtc);
        await _counts.Received(1).GetCountsAsync(new DateOnly(2026, 10, 17), Now, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task A_fresh_feed_is_not_delayed_and_reports_its_last_pull()
    {
        var feeds = (await RunAsync(Feed(TimeSpan.FromHours(2)))).Feeds;

        Assert.False(feeds.IsDelayed);
        Assert.Equal(Now - TimeSpan.FromHours(2), feeds.LastSuccessAtUtc);
        Assert.Equal(IngestionJobStatus.Succeeded, feeds.LastAttemptStatus);
    }

    [Fact]
    public async Task A_stale_feed_or_one_that_never_succeeded_is_delayed()
    {
        Assert.True((await RunAsync(Feed(TimeSpan.FromHours(40)))).Feeds.IsDelayed);
        Assert.True((await RunAsync(Feed(null, IngestionJobStatus.Failed))).Feeds.IsDelayed);
    }

    [Fact]
    public async Task No_scheduled_feeds_means_nothing_is_delayed()
    {
        var feeds = (await RunAsync()).Feeds;

        Assert.False(feeds.IsDelayed);
        Assert.Null(feeds.LastSuccessAtUtc);
        Assert.Null(feeds.LastAttemptStatus);
    }
}
