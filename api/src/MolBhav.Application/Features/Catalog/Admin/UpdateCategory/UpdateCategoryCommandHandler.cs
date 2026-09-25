using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateCategory;

internal sealed class UpdateCategoryCommandHandler(IProcurementCategoryRepository categories, ILanguageContext languageContext)
    : ICommandHandler<UpdateCategoryCommand>
{
    public async Task<Result> Handle(UpdateCategoryCommand request, CancellationToken cancellationToken)
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

        return category.Update(request.IconKey, request.DisplayOrder, request.IsActive!.Value, translations.Value);
    }
}
