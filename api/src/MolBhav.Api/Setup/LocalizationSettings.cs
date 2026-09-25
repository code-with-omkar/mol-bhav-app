namespace MolBhav.Api.Setup;

/// <summary>
/// Enabled languages are configuration, not code: adding an Indian language = config + ARB/LocalizedTexts data.
/// Arrays default to empty because the configuration binder appends to (not replaces) pre-populated collections.
/// </summary>
public sealed class LocalizationSettings
{
    public const string SectionName = "Localization";

    private static readonly string[] FallbackLanguages = ["en", "hi", "mr", "gu", "ta", "te", "kn"];

    public string DefaultLanguage { get; set; } = "en";

    public string[] SupportedLanguages { get; set; } = [];

    public IReadOnlyList<string> GetSupportedLanguages() =>
        SupportedLanguages.Length == 0 ? FallbackLanguages : SupportedLanguages;
}
