using MolBhav.Domain.Procurement;

namespace MolBhav.Application.Features.Alerting.Opportunities;

/// <summary>
/// Per-unit price of buying at another market and bringing the goods home: the market price plus every active cost
/// component — percentages on the price, fixed amounts spread over the reference order size. Buying in the home
/// district carries no extra cost, which is what makes a nearby market win over a slightly cheaper far one.
/// </summary>
internal static class LandedCost
{
    public static decimal PerUnit(decimal price, IReadOnlyList<CostComponent> components, decimal referenceQuantity)
    {
        ArgumentNullException.ThrowIfNull(components);

        var extra = 0m;
        foreach (var component in components)
        {
            extra += component.ComponentType == CostComponentType.Fixed
                ? component.Value / Math.Max(referenceQuantity, 1m)
                : component.Apply(price);
        }

        return decimal.Round(price + extra, 2, MidpointRounding.AwayFromZero);
    }

    public static decimal SavingsPercent(decimal homePrice, decimal landedPrice) =>
        homePrice <= 0 ? 0 : (homePrice - landedPrice) / homePrice * 100m;
}
