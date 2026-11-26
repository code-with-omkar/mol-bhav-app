using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Abstractions.Pricing;

/// <summary>Dapper-backed pricing reads for the mobile comparison/trend screens and the admin portal.</summary>
public interface IPricingReadService
{
    /// <summary>Most recent non-voided record per location for a product — the comparison matrix (BRD §10).</summary>
    Task<PagedResult<LatestPriceResponse>> GetLatestPricesAsync(LatestPriceFilter filter, CancellationToken cancellationToken = default);

    /// <summary>Most recent non-voided record per product/variant at one location since a date — browse-by-mandi.</summary>
    Task<PagedResult<LocationLatestPriceResponse>> GetLatestByLocationAsync(LatestByLocationFilter filter, CancellationToken cancellationToken = default);

    /// <summary>Non-voided records for one product at one location, oldest first — trend sparklines (BRD §11/§12).</summary>
    Task<IReadOnlyList<PriceHistoryPointResponse>> GetPriceHistoryAsync(PriceHistoryFilter filter, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AdminPriceSourceResponse>> GetAdminPriceSourcesAsync(CancellationToken cancellationToken = default);

    Task<PagedResult<AdminPriceRecordResponse>> GetAdminPriceRecordsAsync(AdminPriceRecordFilter filter, CancellationToken cancellationToken = default);
}

/// <param name="StateId">Only markets and suppliers of this state.</param>
/// <param name="LocationId">Only this one market or supplier.</param>
/// <param name="SinceDate">Ignore a location whose newest price is older than this.</param>
/// <param name="CheapestFirst">Order by price instead of by place, so the first page holds the cheapest.</param>
public sealed record LatestPriceFilter(
    Guid ProductId,
    LocationKind? LocationKind,
    Guid? DistrictId,
    PageRequest Page,
    Guid? StateId = null,
    Guid? LocationId = null,
    DateOnly? SinceDate = null,
    bool CheapestFirst = false);

public sealed record LatestByLocationFilter(
    LocationKind LocationKind,
    Guid LocationId,
    DateOnly SinceDate,
    LanguagePreference Language,
    PageRequest Page);

public sealed record PriceHistoryFilter(Guid ProductId, LocationKind LocationKind, Guid LocationId, DateOnly FromDate, DateOnly ToDate);

public sealed record AdminPriceRecordFilter(
    Guid? ProductId,
    LocationKind? LocationKind,
    Guid? LocationId,
    DateOnly? FromDate,
    DateOnly? ToDate,
    bool? IsVoided,
    PageRequest Page);
