using FluentValidation;
using MolBhav.Domain.Catalog;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateUnit;

internal sealed class UpdateUnitCommandValidator : AbstractValidator<UpdateUnitCommand>
{
    public UpdateUnitCommandValidator()
    {
        RuleFor(x => x.UnitId).NotEmpty();
        RuleFor(x => x.IsActive).NotNull().WithMessage("isActive is required (full replacement — omitting it must not deactivate the item).");
        RuleFor(x => x.Symbol).NotEmpty().MaximumLength(UnitOfMeasure.SymbolMaxLength);
        RuleFor(x => x.Translations).TranslationsRules();
    }
}
