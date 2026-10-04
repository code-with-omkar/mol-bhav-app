using MolBhav.Domain.Monetization;
using static MolBhav.UnitTests.Monetization.MonetizationTestData;

namespace MolBhav.UnitTests.Monetization;

public sealed class FeatureGrantTests
{
    private static FeatureGrant ReportGrant() =>
        FeatureGrant.Create(UserId, MonetizedFeature.PriceHistoryReport, 1, FeatureGrantSource.RewardedAds, Now, TimeSpan.FromHours(24)).Value;

    [Fact]
    public void Consume_Usable_MarksConsumed()
    {
        var grant = ReportGrant();

        var result = grant.Consume(Now.AddHours(1));

        Assert.True(result.IsSuccess);
        Assert.False(grant.IsUsable(Now.AddHours(1)));
    }

    [Fact]
    public void Consume_Twice_FailsAlreadyConsumed()
    {
        var grant = ReportGrant();
        grant.Consume(Now.AddHours(1));

        Assert.Equal(MonetizationErrors.GrantAlreadyConsumed, grant.Consume(Now.AddHours(2)).Error);
    }

    [Fact]
    public void Consume_AfterExpiry_FailsExpired()
    {
        var grant = ReportGrant();

        Assert.Equal(MonetizationErrors.GrantExpired, grant.Consume(Now.AddHours(24)).Error);
    }

    [Fact]
    public void Consume_SlotGrant_Fails()
    {
        var grant = FeatureGrant.Create(UserId, MonetizedFeature.WatchlistSlots, 5, FeatureGrantSource.RewardedAds, Now, null).Value;

        Assert.True(grant.Consume(Now).IsFailure);
        Assert.True(grant.IsUsable(Now.AddYears(5)));
    }

    [Fact]
    public void ForCompletedSession_GrantedSession_UsesConfiguredTerms()
    {
        var session = Session(MonetizedFeature.AlertRuleSlots, adsRequired: 1);
        session.RecordVerifiedAd(Now);

        var grant = FeatureGrant.ForCompletedSession(session, Limits(), FeatureGrantSource.RewardedAds, Now);

        Assert.True(grant.IsSuccess);
        Assert.Equal(2, grant.Value.Quantity);
        Assert.Equal(MonetizedFeature.AlertRuleSlots, grant.Value.Feature);
        Assert.Null(grant.Value.ExpiresAtUtc);
    }

    [Fact]
    public void ForCompletedSession_PendingSession_Fails()
    {
        var session = Session(MonetizedFeature.PriceHistoryReport, adsRequired: 2);

        Assert.True(FeatureGrant.ForCompletedSession(session, Limits(), FeatureGrantSource.RewardedAds, Now).IsFailure);
    }
}
