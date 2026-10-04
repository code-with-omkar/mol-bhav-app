using MolBhav.Domain.Monetization;
using static MolBhav.UnitTests.Monetization.MonetizationTestData;

namespace MolBhav.UnitTests.Monetization;

public sealed class FreeTierLimitsTests
{
    [Theory]
    [InlineData(0, 10)]
    [InlineData(5, 15)]
    [InlineData(15, 25)]
    [InlineData(40, 25)]
    public void Capacity_GrowsWithUnlocks_UpToMaximum(int unlocked, int expected)
    {
        Assert.Equal(expected, Limits().Watchlist.Capacity(unlocked));
    }

    [Fact]
    public void CanUnlockMore_AtMaximum_IsFalse()
    {
        Assert.False(Limits().Watchlist.CanUnlockMore(15));
    }

    [Fact]
    public void CanUnlockMore_BelowMaximum_IsTrue()
    {
        Assert.True(Limits().AlertRules.CanUnlockMore(4));
    }

    [Fact]
    public void GrantTermsFor_Report_IsOneTimeLimited()
    {
        var (quantity, lifetime) = Limits().GrantTermsFor(MonetizedFeature.PriceHistoryReport);

        Assert.Equal(1, quantity);
        Assert.Equal(TimeSpan.FromHours(24), lifetime);
    }

    [Fact]
    public void GrantTermsFor_Watchlist_IsPermanentSlots()
    {
        var (quantity, lifetime) = Limits().GrantTermsFor(MonetizedFeature.WatchlistSlots);

        Assert.Equal(5, quantity);
        Assert.Null(lifetime);
    }

    [Fact]
    public void IsValid_MaximumBelowIncluded_IsFalse()
    {
        var limits = Limits() with { Watchlist = new SlotAllowance(10, 5, 9, 1) };

        Assert.False(limits.IsValid);
    }
}
