using System.Globalization;
using Microsoft.Extensions.Options;
using MolBhav.Api.Setup;
using MolBhav.Application.Abstractions.Localization;

namespace MolBhav.Api.Services;

/// <summary>Reads the UI culture set by the request-localization middleware; falls back to the default outside a request.</summary>
internal sealed class RequestLanguageContext(IOptions<LocalizationSettings> settings) : ILanguageContext
{
    public string DefaultLanguage => settings.Value.DefaultLanguage;

    public string CurrentLanguage
    {
        get
        {
            var language = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName;
            return settings.Value.GetSupportedLanguages().Contains(language, StringComparer.OrdinalIgnoreCase)
                ? language
                : DefaultLanguage;
        }
    }
}
