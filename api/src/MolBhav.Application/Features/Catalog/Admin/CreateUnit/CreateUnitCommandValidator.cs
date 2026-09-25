using FluentValidation;
using MolBhav.Domain.Catalog;

namespace MolBhav.Application.Features.Catalog.Admin.CreateUnit;

internal sealed class CreateUnitCommandValidator : AbstractValidator<CreateUnitCommand>
{
    public CreateUnitCommandValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(CatalogCode.MaxLength);
        RuleFor(x => x.Symbol).NotEmpty().MaximumLength(UnitOfMeasure.SymbolMaxLength);
        RuleFor(x => x.Dimension).NotNull().IsInEnum();
        RuleFor(x => x.ToBaseFactor).NotNull().GreaterThan(0m).PrecisionScale(18, UnitOfMeasure.FactorScale, ignoreTrailingZeros: true);
        RuleFor(x => x.Translations).TranslationsRules();
    }
}
