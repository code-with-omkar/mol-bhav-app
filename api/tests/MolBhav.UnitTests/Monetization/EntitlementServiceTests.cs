using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Monetization;
using MolBhav.Application.Abstractions.Watchlist;
using MolBhav.Application.Features.Monetization;
using MolBhav.Domain.Monetization;
using MolBhav.UnitTests.Billing;
using static MolBhav.UnitTests.Monetization.MonetizationTestData;

namespace MolBhav.UnitTests.Monetization;

public sealed class EntitlementServiceTests
{
    private readonly ICurrentUser _currentUser = Substitute.For<ICurrentUser>();
    private readonly IFeatureGrantRepository _grants = Substitute.For<IFeatureGrantRepository>();
    private readonly IWatchlistItemRepository _watchlist = Substitute.For<IWatchlistItemRepository>();
    private readonly IAlertRuleRepository _alertRules = Substitute.For<IAlertRuleRepository>();
    private readonly EntitlementService _service;

    public EntitlementServiceTests()
    {
        _currentUser.GetRequiredUserId().Returns(UserId);
        _currentUser.SubscriptionTier.Returns(SubscriptionTiers.Free);

        var policy = Substitute.For<IFreeTierPolicy>();
        policy.Limits.Returns(Limits());

        _service = new EntitlementService(_currentUser, policy, _grants, _watchlist, _alertRules, new FixedTimeProvider(Now));
    }

    [Fact]
    public async Task EnsureCanAdd_FreeUserBelowCapacity_Succeeds()
    {
        _watchlist.CountByUserAsync(UserId, Arg.Any<CancellationToken>()).Returns(9);

        var result = await _service.EnsureCanAddAsync(MonetizedFeature.WatchlistSlots, CancellationToken.None);

        Assert.True(result.IsSuccess);
    }

    [Fact]
    public async Task EnsureCanAdd_FreeUserAtCapacity_FailsWatchlistLimit()
    {
        _watchlist.CountByUserAsync(UserId, Arg.Any<CancellationToken>()).Returns(10);

        var result = await _service.EnsureCanAddAsync(MonetizedFeature.WatchlistSlots, CancellationToken.None);

        Assert.Equal(MonetizationErrors.WatchlistLimitReached, result.Error);
    }

    [Fact]
    public async Task EnsureCanAdd_UnlockedSlots_RaiseCapacity()
    {
        _watchlist.CountByUserAsync(UserId, Arg.Any<CancellationToken>()).Returns(12);
        _grants.SumQuantityAsync(UserId, MonetizedFeature.WatchlistSlots, Arg.Any<CancellationToken>()).Returns(5);

        var result = await _service.EnsureCanAddAsync(MonetizedFeature.WatchlistSlots, CancellationToken.None);

        Assert.True(result.IsSuccess);
    }

    [Fact]
    public async Task EnsureCanAdd_AlertRulesAtCapacity_FailsAlertLimit()
    {
        _alertRules.CountByUserAsync(UserId, Arg.Any<CancellationToken>()).Returns(5);

        var result = await _service.EnsureCanAddAsync(MonetizedFeature.AlertRuleSlots, CancellationToken.None);

        Assert.Equal(MonetizationErrors.AlertRuleLimitReached, result.Error);
    }

    [Fact]
    public async Task EnsureCanAdd_ProUser_SucceedsWithoutCounting()
    {
        _currentUser.SubscriptionTier.Returns(SubscriptionTiers.Pro);

        var result = await _service.EnsureCanAddAsync(MonetizedFeature.WatchlistSlots, CancellationToken.None);

        Assert.True(result.IsSuccess);
        await _watchlist.DidNotReceive().CountByUserAsync(Arg.Any<Guid>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task AuthorizeProReport_FreeUserWithoutUnlock_FailsProRequired()
    {
        _grants.GetUsableAsync(UserId, MonetizedFeature.PriceHistoryReport, Now, Arg.Any<CancellationToken>()).Returns([]);

        var result = await _service.AuthorizeProReportAsync(CancellationToken.None);

        Assert.Equal(MonetizationErrors.ReportProRequired, result.Error);
    }

    [Fact]
    public async Task AuthorizeProReport_FreeUserWithUnlock_ConsumesIt()
    {
        var grant = FeatureGrant.Create(UserId, MonetizedFeature.PriceHistoryReport, 1, FeatureGrantSource.RewardedAds, Now.AddHours(-1), TimeSpan.FromHours(24)).Value;
        _grants.GetUsableAsync(UserId, MonetizedFeature.PriceHistoryReport, Now, Arg.Any<CancellationToken>()).Returns([grant]);

        var result = await _service.AuthorizeProReportAsync(CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(Now, grant.ConsumedAtUtc);
    }

    [Fact]
    public async Task EnsureCanStartUnlock_WatchlistAtMaximum_FailsLimitReached()
    {
        _grants.SumQuantityAsync(UserId, MonetizedFeature.WatchlistSlots, Arg.Any<CancellationToken>()).Returns(15);

        var result = await _service.EnsureCanStartUnlockAsync(MonetizedFeature.WatchlistSlots, CancellationToken.None);

        Assert.Equal(MonetizationErrors.UnlockLimitReached, result.Error);
    }

    [Fact]
    public async Task EnsureCanStartUnlock_ReportDailyCapUsed_FailsLimitReached()
    {
        _grants.CountGrantedSinceAsync(UserId, MonetizedFeature.PriceHistoryReport, null, Arg.Any<DateTimeOffset>(), Arg.Any<CancellationToken>())
            .Returns(2);

        var result = await _service.EnsureCanStartUnlockAsync(MonetizedFeature.PriceHistoryReport, CancellationToken.None);

        Assert.Equal(MonetizationErrors.UnlockLimitReached, result.Error);
    }

    [Fact]
    public async Task EnsureCanStartUnlock_ProUser_FailsNotNeeded()
    {
        _currentUser.SubscriptionTier.Returns(SubscriptionTiers.Pro);

        var result = await _service.EnsureCanStartUnlockAsync(MonetizedFeature.PriceHistoryReport, CancellationToken.None);

        Assert.Equal(MonetizationErrors.UnlockNotNeeded, result.Error);
    }

    [Fact]
    public async Task EnsureCanStartUnlock_ReportDailyCap_CountsFromIstMidnight()
    {
        await _service.EnsureCanStartUnlockAsync(MonetizedFeature.PriceHistoryReport, CancellationToken.None);

        // Now is 2026-10-03 05:00 UTC = 10:30 IST; the IST day began 2026-10-02 18:30 UTC.
        await _grants.Received().CountGrantedSinceAsync(
            UserId, MonetizedFeature.PriceHistoryReport, null, new DateTimeOffset(2026, 10, 2, 18, 30, 0, TimeSpan.Zero), Arg.Any<CancellationToken>());
    }
}
