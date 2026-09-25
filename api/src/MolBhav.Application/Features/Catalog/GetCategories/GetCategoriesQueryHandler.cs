using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.GetCategories;

internal sealed class GetCategoriesQueryHandler(ICatalogReadService readService, ILanguageContext languageContext)
    : IQueryHandler<GetCategoriesQuery, IReadOnlyList<CategoryResponse>>
{
    public async Task<Result<IReadOnlyList<CategoryResponse>>> Handle(GetCategoriesQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetCategoriesAsync(CatalogLanguage.From(languageContext), cancellationToken));
}
