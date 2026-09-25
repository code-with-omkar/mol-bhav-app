namespace MolBhav.Application.Abstractions.Catalog;

/// <summary>Catalog facts other modules need without depending on catalog internals (Identity onboarding, later Watchlist/Alerts).</summary>
public interface IProcurementCategoryLookup
{
    /// <summary>The subset of <paramref name="codes"/> that are existing, active categories.</summary>
    Task<IReadOnlySet<string>> GetActiveCodesAsync(IReadOnlyCollection<string> codes, CancellationToken cancellationToken = default);
}
