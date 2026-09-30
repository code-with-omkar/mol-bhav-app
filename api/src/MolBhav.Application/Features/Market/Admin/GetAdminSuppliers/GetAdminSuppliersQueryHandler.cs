using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Market.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Market.Admin.GetAdminSuppliers;

internal sealed class GetAdminSuppliersQueryHandler(IMarketReadService readService)
    : IQueryHandler<GetAdminSuppliersQuery, PagedResult<AdminSupplierResponse>>
{
    public async Task<Result<PagedResult<AdminSupplierResponse>>> Handle(GetAdminSuppliersQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminSuppliersAsync(
            request.DistrictId,
            string.IsNullOrWhiteSpace(request.Search) ? null : request.Search.Trim(),
            request.IsActive,
            new PageRequest(request.Page, request.PageSize),
            cancellationToken));
}
