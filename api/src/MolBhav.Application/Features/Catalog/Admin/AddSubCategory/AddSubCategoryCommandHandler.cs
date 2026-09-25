using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.AddSubCategory;

internal sealed class AddSubCategoryCommandHandler(IProcurementCategoryRepository categories, ILanguageContext languageContext)
    : ICommandHandler<AddSubCategoryCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(AddSubCategoryCommand request, CancellationToken cancellationToken)
    {
        var category = await categories.GetByIdAsync(request.CategoryId, cancellationToken);
        if (category is null)
        {
            return Error.NotFound("ProcurementCategory.NotFound", "Category not found.");
        }

        var code = CatalogCode.Create(request.Code);
        if (code.IsFailure)
        {
            return Result.Failure<CreatedResponse>(code.Error);
        }

        var translations = CatalogTranslationMapper.ToDomain(request.Translations, languageContext.SupportedLanguages);
        if (translations.IsFailure)
        {
            return Result.Failure<CreatedResponse>(translations.Error);
        }

        var subCategory = category.AddSubCategory(code.Value, request.DisplayOrder, translations.Value);
        return subCategory.IsSuccess
            ? new CreatedResponse(subCategory.Value.Id)
            : Result.Failure<CreatedResponse>(subCategory.Error);
    }
}
