using MolBhav.Domain.Common.Results;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Domain.Localization;

/// <summary>Invariants and in-place synchronisation for a <see cref="LocalizedTextEntry"/>'s translation set.</summary>
internal static class LocalizedTextValues
{
    /// <summary>English (the fallback every read resolves to) is required; at most one entry per language.</summary>
    public static Result Validate(IReadOnlyCollection<LocalizedTextValue> values)
    {
        ArgumentNullException.ThrowIfNull(values);

        if (!values.Any(v => v.LanguageCode == LanguageCode.English.Value))
        {
            return Error.Validation(
                "LocalizedTextValue.EnglishRequired",
                "An English text is required: it is the fallback for every other language.");
        }

        var duplicate = values
            .GroupBy(v => v.LanguageCode, StringComparer.Ordinal)
            .FirstOrDefault(g => g.Count() > 1);

        return duplicate is null
            ? Result.Success()
            : Error.Validation("LocalizedTextValue.DuplicateLanguage", $"Language '{duplicate.Key}' is given more than once.");
    }

    /// <summary>Diffs by language so EF issues real UPDATE/INSERT/DELETEs instead of clear-and-re-add.</summary>
    public static void Sync(List<LocalizedTextValue> target, IReadOnlyCollection<LocalizedTextValue> desired)
    {
        var byLanguage = desired.ToDictionary(v => v.LanguageCode, StringComparer.Ordinal);

        target.RemoveAll(existing => !byLanguage.ContainsKey(existing.LanguageCode));

        foreach (var existing in target)
        {
            existing.CopyTextFrom(byLanguage[existing.LanguageCode]);
        }

        var present = target.Select(v => v.LanguageCode).ToHashSet(StringComparer.Ordinal);
        target.AddRange(desired.Where(v => !present.Contains(v.LanguageCode)));
    }
}
