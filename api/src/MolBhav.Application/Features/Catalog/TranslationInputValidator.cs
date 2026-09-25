using FluentValidation;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Catalog;

internal sealed class TranslationInputValidator : AbstractValidator<TranslationInput>
{
    public TranslationInputValidator()
    {
        RuleFor(x => x.LanguageCode).NotEmpty().Length(LanguageCode.MaxLength);
        RuleFor(x => x.Name).NotEmpty().MaximumLength(CatalogTranslation.NameMaxLength);
        RuleFor(x => x.Description).MaximumLength(CatalogTranslation.DescriptionMaxLength);
    }
}

internal static class CatalogValidationRules
{
    /// <summary>Upper bound on languages per item (the platform supports 7 today).</summary>
    public const int MaxTranslations = 20;

    public static void TranslationsRules<T>(this IRuleBuilder<T, IReadOnlyCollection<TranslationInput>> rule) =>
        rule.NotNull()
            .NotEmpty().WithMessage("At least an English name is required.")
            .Must(t => t.Count <= MaxTranslations).WithMessage($"At most {MaxTranslations} translations are allowed.")
            .ForEach(item => item.NotNull().SetValidator(new TranslationInputValidator()));

    public static void DisplayOrderRules<T>(this IRuleBuilder<T, int> rule) =>
        rule.InclusiveBetween(0, CatalogRules.MaxDisplayOrder);
}
