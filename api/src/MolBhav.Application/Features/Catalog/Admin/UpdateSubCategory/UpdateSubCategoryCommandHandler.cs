using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateSubCategory;

internal sealed class UpdateSubCategoryCommandHandler(IProcurementCategoryRepository categories, ILanguageContext languageContext)
    : ICommandHandler<UpdateSubCategoryCommand>
{
    public async Task<Result> Handle(UpdateSubCategoryCommand request, CancellationToken cancellationToken)
    {
        var category = await categories.GetByIdAsync(request.CategoryId, cancellationToken);
        if (category is null)
        {
            return Error.NotFound("ProcurementCategory.NotFound", "Category not found.");
        }

        var translations = CatalogTranslationMapper.ToDomain(request.Translations, languageContext.SupportedLanguages);
        if (translations.IsFailure)
        {
            return translations.Error;
        }

        return category.UpdateSubCategory(request.SubCategoryId, request.DisplayOrder, request.IsActive!.Value, translations.Value);
    }
}
