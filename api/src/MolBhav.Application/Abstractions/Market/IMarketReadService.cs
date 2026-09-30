using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Market.Models;

namespace MolBhav.Application.Abstractions.Market;

/// <summary>Dapper-backed market/location reads for the mobile screens and the admin portal.</summary>
public interface IMarketReadService
{
    Task<IReadOnlyList<StateResponse>> GetStatesAsync(CancellationToken cancellationToken = default);

    /// <summary>Null when the state does not exist or is inactive.</summary>
    Task<IReadOnlyList<DistrictResponse>?> GetDistrictsAsync(Guid stateId, CancellationToken cancellationToken = default);

    Task<PagedResult<MandiResponse>> GetMandisAsync(Guid? districtId, string? search, PageRequest page, CancellationToken cancellationToken = default);

    Task<PagedResult<SupplierResponse>> GetSuppliersAsync(Guid? districtId, string? search, PageRequest page, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AdminStateResponse>> GetAdminStatesAsync(CancellationToken cancellationToken = default);

    Task<PagedResult<AdminMandiResponse>> GetAdminMandisAsync(Guid? districtId, string? search, bool? isActive, PageRequest page, CancellationToken cancellationToken = default);

    Task<PagedResult<AdminSupplierResponse>> GetAdminSuppliersAsync(Guid? districtId, string? search, bool? isActive, PageRequest page, CancellationToken cancellationToken = default);
}
