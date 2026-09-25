using FluentValidation;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateVariant;

internal sealed class UpdateVariantCommandValidator : AbstractValidator<UpdateVariantCommand>
{
    public UpdateVariantCommandValidator()
    {
        RuleFor(x => x.ProductId).NotEmpty();
        RuleFor(x => x.VariantId).NotEmpty();
        RuleFor(x => x.IsActive).NotNull().WithMessage("isActive is required (full replacement — omitting it must not deactivate the item).");
        RuleFor(x => x.DisplayOrder).DisplayOrderRules();
        RuleFor(x => x.Translations).TranslationsRules();
    }
}
