using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Catalog.Admin.CreateCategory;

internal sealed class CreateCategoryCommandHandler(IProcurementCategoryRepository categories, ILanguageContext languageContext)
    : ICommandHandler<CreateCategoryCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreateCategoryCommand request, CancellationToken cancellationToken)
    {
        var code = ProcurementCategoryCode.Create(request.Code);
        if (code.IsFailure)
        {
            return Result.Failure<CreatedResponse>(code.Error);
        }

        // Friendly pre-check; the unique index is the race-proof backstop (→ 409).
        if (await categories.CodeExistsAsync(code.Value, cancellationToken))
        {
            return Error.Conflict("ProcurementCategory.CodeTaken", $"Category '{code.Value.Value}' already exists.");
        }

        var translations = CatalogTranslationMapper.ToDomain(request.Translations, languageContext.SupportedLanguages);
        if (translations.IsFailure)
        {
            return Result.Failure<CreatedResponse>(translations.Error);
        }

        var category = ProcurementCategory.Create(code.Value, request.IconKey, request.DisplayOrder, translations.Value);
        if (category.IsFailure)
        {
            return Result.Failure<CreatedResponse>(category.Error);
        }

        categories.Add(category.Value);
        return new CreatedResponse(category.Value.Id);
    }
}
