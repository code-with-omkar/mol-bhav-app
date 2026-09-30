using FluentValidation;
using MolBhav.Domain.Localization;

namespace MolBhav.Application.Features.Localization.Admin.UpdateLocalizedText;

internal sealed class UpdateLocalizedTextCommandValidator : AbstractValidator<UpdateLocalizedTextCommand>
{
    public UpdateLocalizedTextCommandValidator()
    {
        RuleFor(x => x.LocalizedTextId).NotEmpty();
        RuleFor(x => x.Description).MaximumLength(LocalizedTextEntry.DescriptionMaxLength);
        RuleFor(x => x.Translations).TranslationsRules();
    }
}
