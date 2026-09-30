using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Market.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Market.GetSuppliers;

internal sealed class GetSuppliersQueryHandler(IMarketReadService readService) : IQueryHandler<GetSuppliersQuery, PagedResult<SupplierResponse>>
{
    public async Task<Result<PagedResult<SupplierResponse>>> Handle(GetSuppliersQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetSuppliersAsync(
            request.DistrictId,
            string.IsNullOrWhiteSpace(request.Search) ? null : request.Search.Trim(),
            new PageRequest(request.Page, request.PageSize),
            cancellationToken));
}
