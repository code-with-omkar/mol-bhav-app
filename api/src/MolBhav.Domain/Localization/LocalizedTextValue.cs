using MolBhav.Domain.Common.Results;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Domain.Localization;

/// <summary>
/// One language's text for a <see cref="LocalizedTextEntry"/>. Stored in its own table (owner id + language as the
/// key), mirroring <c>Catalog.CatalogTranslation</c> — a generic entry/language/text table could not be FK-bound to
/// the entry the way an owned collection is.
/// </summary>
public sealed class LocalizedTextValue
{
    public const int TextMaxLength = 1000;

    private LocalizedTextValue(string languageCode, string text)
    {
        LanguageCode = languageCode;
        Text = text;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private LocalizedTextValue()
    {
        LanguageCode = string.Empty;
        Text = string.Empty;
    }

    public string LanguageCode { get; private init; }

    public string Text { get; private set; }

    public static Result<LocalizedTextValue> Create(LanguageCode language, string? text)
    {
        ArgumentNullException.ThrowIfNull(language);

        if (string.IsNullOrWhiteSpace(text))
        {
            return Error.Validation("LocalizedTextValue.TextRequired", $"Text is required ({language.Value}).");
        }

        var trimmed = text.Trim();
        return trimmed.Length > TextMaxLength
            ? Error.Validation("LocalizedTextValue.TextTooLong", $"Text cannot exceed {TextMaxLength} characters ({language.Value}).")
            : new LocalizedTextValue(language.Value, trimmed);
    }

    internal void CopyTextFrom(LocalizedTextValue source) => Text = source.Text;
}
