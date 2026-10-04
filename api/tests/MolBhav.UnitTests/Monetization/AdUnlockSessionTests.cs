using MolBhav.Domain.Monetization;
using static MolBhav.UnitTests.Monetization.MonetizationTestData;

namespace MolBhav.UnitTests.Monetization;

public sealed class AdUnlockSessionTests
{
    [Fact]
    public void RecordVerifiedAd_BeforeLastAd_DoesNotGrant()
    {
        var session = Session(MonetizedFeature.PriceHistoryReport, adsRequired: 2);

        var result = session.RecordVerifiedAd(Now.AddMinutes(1));

        Assert.True(result.IsSuccess);
        Assert.False(result.Value);
        Assert.Equal(AdUnlockSessionStatus.Pending, session.Status);
        Assert.Equal(1, session.AdsVerified);
    }

    [Fact]
    public void RecordVerifiedAd_LastAd_GrantsOnce()
    {
        var session = Session(MonetizedFeature.PriceHistoryReport, adsRequired: 2);
        session.RecordVerifiedAd(Now.AddMinutes(1));

        var result = session.RecordVerifiedAd(Now.AddMinutes(2));

        Assert.True(result.Value);
        Assert.Equal(AdUnlockSessionStatus.Granted, session.Status);
        Assert.Equal(Now.AddMinutes(2), session.GrantedAtUtc);
    }

    [Fact]
    public void RecordVerifiedAd_AfterGrant_FailsAlreadyGranted()
    {
        var session = Session(MonetizedFeature.WatchlistSlots, adsRequired: 1);
        session.RecordVerifiedAd(Now);

        var result = session.RecordVerifiedAd(Now.AddMinutes(1));

        Assert.Equal(MonetizationErrors.SessionAlreadyGranted, result.Error);
    }

    [Fact]
    public void RecordVerifiedAd_AfterExpiry_FailsExpired()
    {
        var session = Session(MonetizedFeature.WatchlistSlots, adsRequired: 1);

        var result = session.RecordVerifiedAd(Now.AddMinutes(30));

        Assert.Equal(MonetizationErrors.SessionExpired, result.Error);
        Assert.Equal(0, session.AdsVerified);
    }

    [Fact]
    public void CompleteWithoutAds_Open_Grants()
    {
        var session = Session(MonetizedFeature.AlertRuleSlots, adsRequired: 1);

        var result = session.CompleteWithoutAds(Now.AddMinutes(1));

        Assert.True(result.IsSuccess);
        Assert.Equal(AdUnlockSessionStatus.Granted, session.Status);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Start_NoAdsRequired_Fails(int adsRequired)
    {
        var result = AdUnlockSession.Start(UserId, MonetizedFeature.WatchlistSlots, adsRequired, Now, TimeSpan.FromMinutes(30));

        Assert.True(result.IsFailure);
    }
}
