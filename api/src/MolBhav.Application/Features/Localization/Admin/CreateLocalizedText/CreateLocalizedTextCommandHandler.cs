using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Localization;

namespace MolBhav.Application.Features.Localization.Admin.CreateLocalizedText;

internal sealed class CreateLocalizedTextCommandHandler(ILocalizedTextRepository texts, ILanguageContext languageContext)
    : ICommandHandler<CreateLocalizedTextCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreateLocalizedTextCommand request, CancellationToken cancellationToken)
    {
        var key = LocalizationKey.Create(request.Key);
        if (key.IsFailure)
        {
            return Result.Failure<CreatedResponse>(key.Error);
        }

        // Friendly pre-check; the unique index is the race-proof backstop (→ 409).
        if (await texts.KeyExistsAsync(key.Value, cancellationToken))
        {
            return Error.Conflict("LocalizedTextEntry.KeyTaken", $"Key '{key.Value.Value}' already exists.");
        }

        var translations = LocalizedTextTranslationMapper.ToDomain(request.Translations, languageContext.SupportedLanguages);
        if (translations.IsFailure)
        {
            return Result.Failure<CreatedResponse>(translations.Error);
        }

        var entry = LocalizedTextEntry.Create(key.Value, request.Description, translations.Value);
        if (entry.IsFailure)
        {
            return Result.Failure<CreatedResponse>(entry.Error);
        }

        texts.Add(entry.Value);
        return new CreatedResponse(entry.Value.Id);
    }
}
