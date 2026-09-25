namespace MolBhav.Application.Abstractions.Localization;

/// <summary>
/// Language negotiated for the current request (Accept-Language → configured supported set → default).
/// Read services use it to pick localized names from the LocalizedTexts store with fallback to the default language.
/// </summary>
public interface ILanguageContext
{
    string CurrentLanguage { get; }

    string DefaultLanguage { get; }
}
