using MolBhav.Application.Features.Alerting.Opportunities;

namespace MolBhav.UnitTests.Ingestion;

/// <summary>A typing mistake in the feed must never look like a bargain.</summary>
public sealed class ImplausiblePriceTests
{
    [Fact]
    public void Prices_far_under_the_middle_one_are_left_out()
    {
        var kept = PlausiblePrices.Of<decimal>([0.0001m, 0.025m, 12m, 14m, 15m, 35m], p => p);

        Assert.Equal([12m, 14m, 15m, 35m], kept);
    }

    [Fact]
    public void A_real_saving_is_kept()
    {
        Assert.Equal([1400m, 4050m], PlausiblePrices.Of<decimal>([1400m, 4050m], p => p));
    }

    [Fact]
    public void Nothing_in_nothing_out() => Assert.Empty(PlausiblePrices.Of<decimal>([], p => p));
}
