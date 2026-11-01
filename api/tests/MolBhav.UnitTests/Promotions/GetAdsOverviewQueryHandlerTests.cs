using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Application.Features.Promotions.Admin.GetAdsOverview;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Promotions;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Promotions;

public sealed class GetAdsOverviewQueryHandlerTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 17, 6, 30, 0, TimeSpan.Zero); // 12:00 IST, 17 Oct

    private readonly IPromotionReadService _readService = Substitute.For<IPromotionReadService>();

    private GetAdsOverviewQueryHandler CreateHandler() => new(_readService, new FixedTimeProvider(Now));

    private static CampaignPerformanceResponse Campaign(string name, long impressions, long clicks) =>
        new(Guid.CreateVersion7(), name, "Advertiser", PromotionPlacement.HomeFeed, CampaignStatus.Active, impressions, clicks, 0);

    [Fact]
    public async Task Defaults_to_the_last_30_IST_days_ending_today()
    {
        var result = await CreateHandler().Handle(new(null, null), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(new DateOnly(2026, 10, 17), result.Value.To);
        Assert.Equal(new DateOnly(2026, 9, 18), result.Value.From);
        await _readService.Received(1).GetCampaignPerformanceAsync(new DateOnly(2026, 9, 18), new DateOnly(2026, 10, 17), Arg.Any<CancellationToken>());
        await _readService.Received(1).GetTotalDailyStatsAsync(new DateOnly(2026, 9, 18), new DateOnly(2026, 10, 17), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Totals_and_click_rate_come_from_the_campaigns()
    {
        _readService.GetCampaignPerformanceAsync(Arg.Any<DateOnly>(), Arg.Any<DateOnly>(), Arg.Any<CancellationToken>())
            .Returns([Campaign("A", 1000, 30), Campaign("B", 500, 15), Campaign("C", 0, 0)]);
        var daily = new[] { new CampaignDailyStatResponse(new DateOnly(2026, 10, 16), 1500, 45) };
        _readService.GetTotalDailyStatsAsync(Arg.Any<DateOnly>(), Arg.Any<DateOnly>(), Arg.Any<CancellationToken>()).Returns(daily);

        var overview = (await CreateHandler().Handle(new(null, null), CancellationToken.None)).Value;

        Assert.Equal(1500, overview.Impressions);
        Assert.Equal(45, overview.Clicks);
        Assert.Equal(3.0, overview.ClickRatePercent);
        Assert.Equal(3, overview.Campaigns.Count);
        Assert.Equal(daily, overview.Daily);
    }

    [Fact]
    public async Task Nothing_shown_means_a_zero_click_rate_not_a_division_error()
    {
        _readService.GetCampaignPerformanceAsync(Arg.Any<DateOnly>(), Arg.Any<DateOnly>(), Arg.Any<CancellationToken>())
            .Returns([Campaign("A", 0, 0)]);

        var overview = (await CreateHandler().Handle(new(null, null), CancellationToken.None)).Value;

        Assert.Equal(0, overview.ClickRatePercent);
    }

    [Fact]
    public async Task A_backwards_or_oversized_range_is_refused_without_querying()
    {
        var backwards = await CreateHandler().Handle(new(new DateOnly(2026, 10, 10), new DateOnly(2026, 10, 1)), CancellationToken.None);
        var tooLong = await CreateHandler().Handle(new(new DateOnly(2025, 1, 1), new DateOnly(2026, 10, 1)), CancellationToken.None);
        var extreme = await CreateHandler().Handle(new(DateOnly.MinValue, null), CancellationToken.None);

        Assert.Equal("AdsOverview.RangeInvalid", backwards.Error.Code);
        Assert.Equal("AdsOverview.RangeInvalid", tooLong.Error.Code);
        Assert.Equal("AdsOverview.RangeInvalid", extreme.Error.Code);
        await _readService.DidNotReceiveWithAnyArgs().GetCampaignPerformanceAsync(default, default, default);
    }
}
