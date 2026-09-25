using FluentValidation;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateSubCategory;

internal sealed class UpdateSubCategoryCommandValidator : AbstractValidator<UpdateSubCategoryCommand>
{
    public UpdateSubCategoryCommandValidator()
    {
        RuleFor(x => x.CategoryId).NotEmpty();
        RuleFor(x => x.SubCategoryId).NotEmpty();
        RuleFor(x => x.IsActive).NotNull().WithMessage("isActive is required (full replacement — omitting it must not deactivate the item).");
        RuleFor(x => x.DisplayOrder).DisplayOrderRules();
        RuleFor(x => x.Translations).TranslationsRules();
    }
}
