using FluentValidation;
using MolBhav.Domain.Catalog;

namespace MolBhav.Application.Features.Catalog.Admin.CreateProduct;

internal sealed class CreateProductCommandValidator : AbstractValidator<CreateProductCommand>
{
    public CreateProductCommandValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(CatalogCode.MaxLength);
        RuleFor(x => x.SubCategoryId).NotEmpty();
        RuleFor(x => x.DefaultUnitId).NotEmpty();
        RuleFor(x => x.DisplayOrder).DisplayOrderRules();
        RuleFor(x => x.ImageKey).MaximumLength(Product.ImageKeyMaxLength);
        RuleFor(x => x.Translations).TranslationsRules();
    }
}
