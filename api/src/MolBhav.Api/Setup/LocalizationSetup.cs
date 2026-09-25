using Microsoft.AspNetCore.Localization;

namespace MolBhav.Api.Setup;

internal static class LocalizationSetup
{
    public static IServiceCollection AddRequestLanguageNegotiation(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<LocalizationSettings>()
            .Bind(configuration.GetSection(LocalizationSettings.SectionName))
            .Validate(
                s => s.GetSupportedLanguages().Contains(s.DefaultLanguage, StringComparer.OrdinalIgnoreCase),
                "Localization:DefaultLanguage must be one of Localization:SupportedLanguages.")
            .ValidateOnStart();

        var settings = configuration.GetSection(LocalizationSettings.SectionName).Get<LocalizationSettings>() ?? new LocalizationSettings();
        var languages = settings.GetSupportedLanguages().ToArray();

        services.Configure<RequestLocalizationOptions>(options =>
        {
            options.SetDefaultCulture(settings.DefaultLanguage);
            options.AddSupportedCultures(languages);
            options.AddSupportedUICultures(languages);
            options.FallBackToParentCultures = true;
            options.FallBackToParentUICultures = true;
            options.ApplyCurrentCultureToResponseHeaders = true;

            // Mobile clients send Accept-Language; cookies/query strings are not used by this API.
            options.RequestCultureProviders = [new AcceptLanguageHeaderRequestCultureProvider()];
        });

        return services;
    }
}
