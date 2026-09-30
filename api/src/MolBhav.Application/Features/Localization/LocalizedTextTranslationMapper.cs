using MolBhav.Application.Features.Localization.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Localization;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Localization;

internal static class LocalizedTextTranslationMapper
{
    /// <summary>Builds domain translations, restricted to the languages the platform serves.</summary>
    public static Result<IReadOnlyCollection<LocalizedTextValue>> ToDomain(
        IReadOnlyCollection<LocalizedTextTranslationInput> inputs,
        IReadOnlyCollection<string> supportedLanguages)
    {
        var translations = new List<LocalizedTextValue>(inputs.Count);

        foreach (var input in inputs)
        {
            var language = LanguageCode.Create(input.LanguageCode);
            if (language.IsFailure)
            {
                return Result.Failure<IReadOnlyCollection<LocalizedTextValue>>(language.Error);
            }

            if (!supportedLanguages.Contains(language.Value.Value, StringComparer.OrdinalIgnoreCase))
            {
                return Error.Validation(
                    "LocalizedTextValue.UnsupportedLanguage",
                    $"Language '{language.Value.Value}' is not enabled. Supported: {string.Join(", ", supportedLanguages)}.");
            }

            var value = LocalizedTextValue.Create(language.Value, input.Text);
            if (value.IsFailure)
            {
                return Result.Failure<IReadOnlyCollection<LocalizedTextValue>>(value.Error);
            }

            translations.Add(value.Value);
        }

        return translations;
    }
}
