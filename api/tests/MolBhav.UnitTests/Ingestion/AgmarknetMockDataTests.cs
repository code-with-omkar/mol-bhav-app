using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Domain.Pricing;
using MolBhav.Infrastructure.Ingestion;

namespace MolBhav.UnitTests.Ingestion;

public sealed class AgmarknetMockDataTests
{
    private static IngestedPriceRecord Onion(DateOnly day) =>
        new("onion", "red", LocationKind.Mandi, "pune", 1300m, 2200m, 1850m, 11000m, day);

    [Fact]
    public void SameDay_GivesTheSameFigures()
    {
        var day = new DateOnly(2026, 10, 3);

        Assert.Equal(AgmarknetIngestionSourceAdapter.VaryForDay(Onion(day)), AgmarknetIngestionSourceAdapter.VaryForDay(Onion(day)));
    }

    [Fact]
    public void Prices_MoveAcrossDays_WithinTwelvePercent()
    {
        var modals = Enumerable.Range(0, 14)
            .Select(i => AgmarknetIngestionSourceAdapter.VaryForDay(Onion(new DateOnly(2026, 9, 20).AddDays(i))).ModalPrice)
            .ToArray();

        Assert.True(modals.Distinct().Count() > 1);
        Assert.All(modals, m => Assert.InRange(m, 1850m * 0.88m, 1850m * 1.12m));
    }
}
