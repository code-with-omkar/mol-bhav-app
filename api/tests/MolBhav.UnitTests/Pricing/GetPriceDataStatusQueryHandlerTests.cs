using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Features.Pricing.GetPriceDataStatus;
using MolBhav.Domain.Ingestion;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Pricing;

public sealed class GetPriceDataStatusQueryHandlerTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 16, 12, 0, 0, TimeSpan.Zero);

    private readonly IIngestionReadService _readService = Substitute.For<IIngestionReadService>();

    private async Task<(bool IsDelayed, DateTimeOffset? LastUpdated)> StatusAsync(params FeedHealth[] feeds)
    {
        _readService.GetScheduledFeedHealthAsync(Arg.Any<CancellationToken>()).Returns(feeds);

        var result = await new GetPriceDataStatusQueryHandler(_readService, new FixedTimeProvider(Now))
            .Handle(new GetPriceDataStatusQuery(), CancellationToken.None);

        Assert.True(result.IsSuccess);
        return (result.Value.IsDelayed, result.Value.LastUpdatedAtUtc);
    }

    private static FeedHealth Feed(TimeSpan? successAgo, IngestionJobStatus? lastAttempt = IngestionJobStatus.Succeeded, string code = "agmarknet") =>
        new(Guid.CreateVersion7(), code, successAgo is { } ago ? Now - ago : null, lastAttempt, lastAttempt is null ? null : Now - TimeSpan.FromMinutes(5));

    [Fact]
    public async Task No_scheduled_feeds_means_nothing_can_be_late()
    {
        var (isDelayed, lastUpdated) = await StatusAsync();

        Assert.False(isDelayed);
        Assert.Null(lastUpdated);
    }

    [Fact]
    public async Task A_recent_successful_pull_is_not_delayed()
    {
        var (isDelayed, lastUpdated) = await StatusAsync(Feed(TimeSpan.FromHours(2)));

        Assert.False(isDelayed);
        Assert.Equal(Now - TimeSpan.FromHours(2), lastUpdated);
    }

    [Fact]
    public async Task A_day_old_pull_is_still_fine_for_a_daily_feed()
    {
        // 06:00 yesterday to 12:00 today = 30h would already be stale, so 25h (a normal gap before today's run) must not be.
        var (isDelayed, _) = await StatusAsync(Feed(TimeSpan.FromHours(25)));

        Assert.False(isDelayed);
    }

    [Fact]
    public async Task No_data_for_more_than_thirty_hours_is_delayed_even_if_nothing_failed()
    {
        var (isDelayed, _) = await StatusAsync(Feed(TimeSpan.FromHours(31)));

        Assert.True(isDelayed);
    }

    [Fact]
    public async Task A_failed_latest_run_is_delayed_once_the_last_success_is_older_than_the_grace_period()
    {
        var (isDelayed, _) = await StatusAsync(Feed(TimeSpan.FromHours(7), IngestionJobStatus.Failed));

        Assert.True(isDelayed);
    }

    [Fact]
    public async Task A_failed_run_right_after_a_good_pull_stays_quiet()
    {
        var (isDelayed, _) = await StatusAsync(Feed(TimeSpan.FromHours(3), IngestionJobStatus.Failed));

        Assert.False(isDelayed);
    }

    [Fact]
    public async Task A_partial_success_counts_as_getting_data_in()
    {
        var (isDelayed, _) = await StatusAsync(Feed(TimeSpan.FromHours(7), IngestionJobStatus.PartiallySucceeded));

        Assert.False(isDelayed);
    }

    [Fact]
    public async Task A_feed_that_never_got_data_in_is_delayed()
    {
        var (isDelayed, lastUpdated) = await StatusAsync(Feed(successAgo: null, lastAttempt: IngestionJobStatus.Failed));

        Assert.True(isDelayed);
        Assert.Null(lastUpdated);
    }

    [Fact]
    public async Task One_late_feed_is_enough_and_last_updated_is_the_newest_success()
    {
        var (isDelayed, lastUpdated) = await StatusAsync(
            Feed(TimeSpan.FromHours(1), code: "agmarknet"),
            Feed(TimeSpan.FromHours(40), code: "construction-rates"));

        Assert.True(isDelayed);
        Assert.Equal(Now - TimeSpan.FromHours(1), lastUpdated);
    }
}
