using FluentValidation;
using MolBhav.Domain.Catalog;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateProduct;

internal sealed class UpdateProductCommandValidator : AbstractValidator<UpdateProductCommand>
{
    public UpdateProductCommandValidator()
    {
        RuleFor(x => x.ProductId).NotEmpty();
        RuleFor(x => x.IsActive).NotNull().WithMessage("isActive is required (full replacement — omitting it must not deactivate the item).");
        RuleFor(x => x.SubCategoryId).NotEmpty();
        RuleFor(x => x.DefaultUnitId).NotEmpty();
        RuleFor(x => x.DisplayOrder).DisplayOrderRules();
        RuleFor(x => x.ImageKey).MaximumLength(Product.ImageKeyMaxLength);
        RuleFor(x => x.Translations).TranslationsRules();
    }
}
