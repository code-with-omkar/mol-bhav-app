using FluentValidation;
using MolBhav.Domain.Localization;

namespace MolBhav.Application.Features.Localization.Admin.CreateLocalizedText;

internal sealed class CreateLocalizedTextCommandValidator : AbstractValidator<CreateLocalizedTextCommand>
{
    public CreateLocalizedTextCommandValidator()
    {
        RuleFor(x => x.Key).NotEmpty().MaximumLength(LocalizationKey.MaxLength);
        RuleFor(x => x.Description).MaximumLength(LocalizedTextEntry.DescriptionMaxLength);
        RuleFor(x => x.Translations).TranslationsRules();
    }
}
