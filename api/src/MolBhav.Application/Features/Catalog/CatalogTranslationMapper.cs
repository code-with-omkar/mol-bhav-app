using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Catalog;

internal static class CatalogTranslationMapper
{
    /// <summary>Builds domain translations, restricted to the languages the platform serves.</summary>
    public static Result<IReadOnlyCollection<CatalogTranslation>> ToDomain(
        IReadOnlyCollection<TranslationInput> inputs,
        IReadOnlyCollection<string> supportedLanguages)
    {
        var translations = new List<CatalogTranslation>(inputs.Count);

        foreach (var input in inputs)
        {
            var language = LanguageCode.Create(input.LanguageCode);
            if (language.IsFailure)
            {
                return Result.Failure<IReadOnlyCollection<CatalogTranslation>>(language.Error);
            }

            if (!supportedLanguages.Contains(language.Value.Value, StringComparer.OrdinalIgnoreCase))
            {
                return Error.Validation(
                    "CatalogTranslation.UnsupportedLanguage",
                    $"Language '{language.Value.Value}' is not enabled. Supported: {string.Join(", ", supportedLanguages)}.");
            }

            var translation = CatalogTranslation.Create(language.Value, input.Name, input.Description);
            if (translation.IsFailure)
            {
                return Result.Failure<IReadOnlyCollection<CatalogTranslation>>(translation.Error);
            }

            translations.Add(translation.Value);
        }

        return translations;
    }
}
