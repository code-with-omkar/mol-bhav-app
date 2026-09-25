using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.GetAdminCategories;

internal sealed class GetAdminCategoriesQueryHandler(ICatalogReadService readService)
    : IQueryHandler<GetAdminCategoriesQuery, IReadOnlyList<AdminCategoryResponse>>
{
    public async Task<Result<IReadOnlyList<AdminCategoryResponse>>> Handle(GetAdminCategoriesQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminCategoriesAsync(cancellationToken));
}
