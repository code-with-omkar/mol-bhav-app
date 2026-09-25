using FluentValidation;
using MolBhav.Domain.Catalog;

namespace MolBhav.Application.Features.Catalog.Admin.AddVariant;

internal sealed class AddVariantCommandValidator : AbstractValidator<AddVariantCommand>
{
    public AddVariantCommandValidator()
    {
        RuleFor(x => x.ProductId).NotEmpty();
        RuleFor(x => x.Code).NotEmpty().MaximumLength(CatalogCode.MaxLength);
        RuleFor(x => x.DisplayOrder).DisplayOrderRules();
        RuleFor(x => x.Translations).TranslationsRules();
    }
}
