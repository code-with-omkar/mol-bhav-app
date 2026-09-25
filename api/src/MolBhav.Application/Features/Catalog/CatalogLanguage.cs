using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;

namespace MolBhav.Application.Features.Catalog;

internal static class CatalogLanguage
{
    public static LanguagePreference From(ILanguageContext context) => new(context.CurrentLanguage, context.DefaultLanguage);
}
