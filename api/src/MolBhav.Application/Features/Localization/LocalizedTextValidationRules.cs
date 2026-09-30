using FluentValidation;
using MolBhav.Application.Features.Localization.Models;
using MolBhav.Domain.Localization;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Localization;

internal sealed class LocalizedTextTranslationInputValidator : AbstractValidator<LocalizedTextTranslationInput>
{
    public LocalizedTextTranslationInputValidator()
    {
        RuleFor(x => x.LanguageCode).NotEmpty().Length(LanguageCode.MaxLength);
        RuleFor(x => x.Text).NotEmpty().MaximumLength(LocalizedTextValue.TextMaxLength);
    }
}

internal static class LocalizedTextValidationRules
{
    /// <summary>Upper bound on languages per key (the platform supports 7 today).</summary>
    public const int MaxTranslations = 20;

    public static void TranslationsRules<T>(this IRuleBuilder<T, IReadOnlyCollection<LocalizedTextTranslationInput>> rule) =>
        rule.NotNull()
            .NotEmpty().WithMessage("At least an English text is required.")
            .Must(t => t.Count <= MaxTranslations).WithMessage($"At most {MaxTranslations} translations are allowed.")
            .ForEach(item => item.NotNull().SetValidator(new LocalizedTextTranslationInputValidator()));
}
