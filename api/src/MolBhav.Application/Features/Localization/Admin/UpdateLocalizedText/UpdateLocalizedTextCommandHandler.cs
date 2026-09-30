using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Localization.Admin.UpdateLocalizedText;

internal sealed class UpdateLocalizedTextCommandHandler(ILocalizedTextRepository texts, ILanguageContext languageContext)
    : ICommandHandler<UpdateLocalizedTextCommand>
{
    public async Task<Result> Handle(UpdateLocalizedTextCommand request, CancellationToken cancellationToken)
    {
        var entry = await texts.GetByIdAsync(request.LocalizedTextId, cancellationToken);
        if (entry is null)
        {
            return Error.NotFound("LocalizedTextEntry.NotFound", "Localized text not found.");
        }

        var translations = LocalizedTextTranslationMapper.ToDomain(request.Translations, languageContext.SupportedLanguages);
        if (translations.IsFailure)
        {
            return translations.Error;
        }

        return entry.Update(request.Description, translations.Value);
    }
}
