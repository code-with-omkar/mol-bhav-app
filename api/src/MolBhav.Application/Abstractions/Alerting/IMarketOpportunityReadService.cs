using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Alerting.Opportunities.Models;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Abstractions.Alerting;

/// <summary>Dapper reads for the opportunity scan and the opportunity screens.</summary>
public interface IMarketOpportunityReadService
{
    /// <summary>Every watchlist item whose owner's profile district resolves to a seeded district.</summary>
    Task<IReadOnlyList<OpportunityWatcher>> GetWatchersAsync(CancellationToken cancellationToken = default);

    /// <summary>Newest non-voided price per product, variant and market since <paramref name="since"/>.</summary>
    Task<IReadOnlyList<OpportunityPrice>> GetLatestPricesAsync(
        IReadOnlyCollection<Guid> productIds,
        DateOnly since,
        CancellationToken cancellationToken = default);

    Task<PagedResult<MarketOpportunityResponse>> GetOpportunitiesAsync(
        Guid userId,
        LanguagePreference language,
        PageRequest page,
        CancellationToken cancellationToken = default);

    /// <summary>One of the user's opportunities, or null when it doesn't exist or belongs to someone else.</summary>
    Task<MarketOpportunityResponse?> GetOpportunityAsync(
        Guid userId,
        Guid opportunityId,
        LanguagePreference language,
        CancellationToken cancellationToken = default);

    /// <summary>Newest price per market for one product/variant since <paramref name="since"/>, with names.</summary>
    Task<IReadOnlyList<OpportunityMarketRow>> GetMarketPricesAsync(
        Guid productId,
        Guid? variantId,
        DateOnly since,
        CancellationToken cancellationToken = default);
}

public sealed record OpportunityWatcher(Guid UserId, Guid ProductId, Guid? VariantId, Guid HomeDistrictId);

public sealed record OpportunityPrice(
    Guid ProductId,
    Guid? VariantId,
    LocationKind LocationKind,
    Guid? MandiId,
    Guid? SupplierId,
    Guid DistrictId,
    decimal ModalPrice,
    DateOnly RecordDate);

public sealed record OpportunityMarketRow(
    LocationKind LocationKind,
    Guid LocationId,
    string Name,
    Guid DistrictId,
    string DistrictName,
    decimal ModalPrice,
    DateOnly RecordDate);
