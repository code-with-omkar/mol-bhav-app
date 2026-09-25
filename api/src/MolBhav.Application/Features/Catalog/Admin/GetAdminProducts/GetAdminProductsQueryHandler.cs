using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.GetAdminProducts;

internal sealed class GetAdminProductsQueryHandler(ICatalogReadService readService)
    : IQueryHandler<GetAdminProductsQuery, PagedResult<AdminProductSummaryResponse>>
{
    public async Task<Result<PagedResult<AdminProductSummaryResponse>>> Handle(GetAdminProductsQuery request, CancellationToken cancellationToken)
    {
        var filter = new AdminProductFilter(
            string.IsNullOrWhiteSpace(request.CategoryCode) ? null : request.CategoryCode.Trim().ToLowerInvariant(),
            request.SubCategoryId,
            string.IsNullOrWhiteSpace(request.Search) ? null : request.Search.Trim(),
            request.IsActive,
            new PageRequest(request.Page, request.PageSize));

        return Result.Success(await readService.GetAdminProductsAsync(filter, cancellationToken));
    }
}
