using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.GetProducts;

internal sealed class GetProductsQueryHandler(ICatalogReadService readService, ILanguageContext languageContext)
    : IQueryHandler<GetProductsQuery, PagedResult<ProductSummaryResponse>>
{
    public async Task<Result<PagedResult<ProductSummaryResponse>>> Handle(GetProductsQuery request, CancellationToken cancellationToken)
    {
        var filter = new ProductListFilter(
            request.CategoryCode.Trim().ToLowerInvariant(),
            request.SubCategoryId,
            string.IsNullOrWhiteSpace(request.Search) ? null : request.Search.Trim(),
            new PageRequest(request.Page, request.PageSize));

        var page = await readService.GetProductsAsync(filter, CatalogLanguage.From(languageContext), cancellationToken);

        return page is null
            ? Error.NotFound("ProcurementCategory.NotFound", $"Category '{filter.CategoryCode}' was not found.")
            : page;
    }
}
