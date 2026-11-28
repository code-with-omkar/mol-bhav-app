namespace MolBhav.Application.Features.Alerting.Opportunities;

/// <summary>
/// The feed carries typing mistakes such as a quintal for Rs 0.01. A price under a tenth of the middle one of the
/// prices it is compared with is treated as no price, so it never becomes an "opportunity".
/// </summary>
internal static class PlausiblePrices
{
    private const decimal LowestShareOfMiddle = 0.1m;

    public static IReadOnlyList<T> Of<T>(IEnumerable<T> items, Func<T, decimal> price)
    {
        var all = items.ToList();
        if (all.Count == 0)
        {
            return all;
        }

        var ordered = all.Select(price).Order().ToList();
        var half = ordered.Count / 2;
        var middle = ordered.Count % 2 == 1 ? ordered[half] : (ordered[half - 1] + ordered[half]) / 2m;
        return all.Where(item => price(item) >= middle * LowestShareOfMiddle).ToList();
    }
}
