using Microsoft.Extensions.Logging.Abstractions;
using MolBhav.Application.Abstractions.Monetization;
using MolBhav.Application.Features.Monetization.RecordRewardedAdView;
using MolBhav.Domain.Monetization;
using MolBhav.UnitTests.Billing;
using static MolBhav.UnitTests.Monetization.MonetizationTestData;

namespace MolBhav.UnitTests.Monetization;

public sealed class RecordRewardedAdViewCommandHandlerTests
{
    private readonly IRewardedAdCallbackVerifier _verifier = Substitute.For<IRewardedAdCallbackVerifier>();
    private readonly IRewardedAdViewRepository _views = Substitute.For<IRewardedAdViewRepository>();
    private readonly IAdUnlockSessionRepository _sessions = Substitute.For<IAdUnlockSessionRepository>();
    private readonly IFeatureGrantRepository _grants = Substitute.For<IFeatureGrantRepository>();
    private readonly RecordRewardedAdViewCommandHandler _handler;

    public RecordRewardedAdViewCommandHandlerTests()
    {
        var policy = Substitute.For<IFreeTierPolicy>();
        policy.Limits.Returns(Limits());

        _handler = new RecordRewardedAdViewCommandHandler(
            _verifier, _views, _sessions, _grants, policy, new FixedTimeProvider(Now.AddMinutes(1)),
            NullLogger<RecordRewardedAdViewCommandHandler>.Instance);
    }

    private void Callback(AdUnlockSession session, string transactionId, Guid? userId = null) =>
        _verifier.VerifyAsync("q", Arg.Any<CancellationToken>()).Returns(new RewardedAdCallback(
            transactionId, (userId ?? session.UserId).ToString(), session.Id.ToString(), "5450213213286189855", "unit", Now));

    [Fact]
    public async Task Handle_InvalidSignature_Fails()
    {
        _verifier.VerifyAsync("q", Arg.Any<CancellationToken>()).Returns((RewardedAdCallback?)null);

        var result = await _handler.Handle(new RecordRewardedAdViewCommand("q"), CancellationToken.None);

        Assert.Equal(MonetizationErrors.InvalidAdCallback, result.Error);
    }

    [Fact]
    public async Task Handle_LastRequiredView_RecordsViewAndGrants()
    {
        var session = Session(MonetizedFeature.WatchlistSlots, adsRequired: 1);
        _sessions.GetByIdAsync(session.Id, Arg.Any<CancellationToken>()).Returns(session);
        Callback(session, "tx-1");

        var result = await _handler.Handle(new RecordRewardedAdViewCommand("q"), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(AdUnlockSessionStatus.Granted, session.Status);
        _views.Received(1).Add(Arg.Is<RewardedAdView>(v => v.TransactionId == "tx-1" && v.SessionId == session.Id));
        _grants.Received(1).Add(Arg.Is<FeatureGrant>(g => g.Feature == MonetizedFeature.WatchlistSlots && g.Quantity == 5));
    }

    [Fact]
    public async Task Handle_FirstOfTwoViews_RecordsViewWithoutGrant()
    {
        var session = Session(MonetizedFeature.PriceHistoryReport, adsRequired: 2);
        _sessions.GetByIdAsync(session.Id, Arg.Any<CancellationToken>()).Returns(session);
        Callback(session, "tx-1");

        await _handler.Handle(new RecordRewardedAdViewCommand("q"), CancellationToken.None);

        Assert.Equal(1, session.AdsVerified);
        _views.Received(1).Add(Arg.Any<RewardedAdView>());
        _grants.DidNotReceive().Add(Arg.Any<FeatureGrant>());
    }

    [Fact]
    public async Task Handle_RepeatedTransaction_IsIgnored()
    {
        var session = Session(MonetizedFeature.WatchlistSlots, adsRequired: 1);
        _sessions.GetByIdAsync(session.Id, Arg.Any<CancellationToken>()).Returns(session);
        _views.ExistsAsync("tx-1", Arg.Any<CancellationToken>()).Returns(true);
        Callback(session, "tx-1");

        var result = await _handler.Handle(new RecordRewardedAdViewCommand("q"), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(0, session.AdsVerified);
        _views.DidNotReceive().Add(Arg.Any<RewardedAdView>());
    }

    [Fact]
    public async Task Handle_SessionOfAnotherUser_IsIgnored()
    {
        var session = Session(MonetizedFeature.WatchlistSlots, adsRequired: 1);
        _sessions.GetByIdAsync(session.Id, Arg.Any<CancellationToken>()).Returns(session);
        Callback(session, "tx-1", userId: Guid.CreateVersion7());

        var result = await _handler.Handle(new RecordRewardedAdViewCommand("q"), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(AdUnlockSessionStatus.Pending, session.Status);
        _grants.DidNotReceive().Add(Arg.Any<FeatureGrant>());
    }
}
