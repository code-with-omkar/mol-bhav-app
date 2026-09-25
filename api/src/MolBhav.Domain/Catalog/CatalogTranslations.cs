using MolBhav.Domain.Common.Results;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Domain.Catalog;

/// <summary>Invariants and in-place synchronisation shared by every translated catalog item.</summary>
internal static class CatalogTranslations
{
    /// <summary>
    /// A set must contain English (the fallback every read resolves to when the requested language is missing)
    /// and at most one entry per language.
    /// </summary>
    public static Result Validate(IReadOnlyCollection<CatalogTranslation> translations)
    {
        ArgumentNullException.ThrowIfNull(translations);

        if (!translations.Any(t => t.LanguageCode == LanguageCode.English.Value))
        {
            return Error.Validation(
                "CatalogTranslation.EnglishRequired",
                "An English name is required: it is the fallback for every other language.");
        }

        var duplicate = translations
            .GroupBy(t => t.LanguageCode, StringComparer.Ordinal)
            .FirstOrDefault(g => g.Count() > 1);

        return duplicate is null
            ? Result.Success()
            : Error.Validation("CatalogTranslation.DuplicateLanguage", $"Language '{duplicate.Key}' is given more than once.");
    }

    /// <summary>
    /// Makes <paramref name="target"/> equal to <paramref name="desired"/> by language: updates text in place, removes
    /// languages no longer present, adds new ones. Diffing (not clear-and-re-add) keeps unchanged rows Unchanged, so
    /// EF issues only the real UPDATE/INSERT/DELETEs rather than deleting and re-inserting the same composite key.
    /// </summary>
    public static void Sync(List<CatalogTranslation> target, IReadOnlyCollection<CatalogTranslation> desired)
    {
        var byLanguage = desired.ToDictionary(t => t.LanguageCode, StringComparer.Ordinal);

        target.RemoveAll(existing => !byLanguage.ContainsKey(existing.LanguageCode));

        foreach (var existing in target)
        {
            existing.CopyTextFrom(byLanguage[existing.LanguageCode]);
        }

        var present = target.Select(t => t.LanguageCode).ToHashSet(StringComparer.Ordinal);
        target.AddRange(desired.Where(t => !present.Contains(t.LanguageCode)));
    }
}
