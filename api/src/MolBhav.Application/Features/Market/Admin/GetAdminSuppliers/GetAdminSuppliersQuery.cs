using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Market.Models;

namespace MolBhav.Application.Features.Market.Admin.GetAdminSuppliers;

public sealed record GetAdminSuppliersQuery(Guid? DistrictId, string? Search, bool? IsActive, int Page, int PageSize)
    : IQuery<PagedResult<AdminSupplierResponse>>;
