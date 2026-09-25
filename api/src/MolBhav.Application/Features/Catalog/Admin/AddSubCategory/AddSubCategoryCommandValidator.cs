using FluentValidation;
using MolBhav.Domain.Catalog;

namespace MolBhav.Application.Features.Catalog.Admin.AddSubCategory;

internal sealed class AddSubCategoryCommandValidator : AbstractValidator<AddSubCategoryCommand>
{
    public AddSubCategoryCommandValidator()
    {
        RuleFor(x => x.CategoryId).NotEmpty();
        RuleFor(x => x.Code).NotEmpty().MaximumLength(CatalogCode.MaxLength);
        RuleFor(x => x.DisplayOrder).DisplayOrderRules();
        RuleFor(x => x.Translations).TranslationsRules();
    }
}
