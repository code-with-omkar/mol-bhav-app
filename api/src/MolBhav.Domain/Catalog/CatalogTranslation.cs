using MolBhav.Domain.Common.Results;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Domain.Catalog;

/// <summary>
/// Display name (and optional description) of a catalog item in one language (BRD §8: localization stored as data).
/// Stored per owner in its own translation table (owner id + language as the key), so every name is FK-bound to the
/// item it names — a generic entity/id/text table could not enforce that.
/// </summary>
public sealed class CatalogTranslation
{
    public const int NameMaxLength = 120;
    public const int DescriptionMaxLength = 500;

    private CatalogTranslation(string languageCode, string name, string? description)
    {
        LanguageCode = languageCode;
        Name = name;
        Description = description;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private CatalogTranslation()
    {
        LanguageCode = string.Empty;
        Name = string.Empty;
    }

    public string LanguageCode { get; private init; }

    public string Name { get; private set; }

    public string? Description { get; private set; }

    public static Result<CatalogTranslation> Create(LanguageCode language, string? name, string? description = null)
    {
        ArgumentNullException.ThrowIfNull(language);

        if (string.IsNullOrWhiteSpace(name))
        {
            return Error.Validation("CatalogTranslation.NameRequired", $"Name is required ({language.Value}).");
        }

        var trimmedName = name.Trim();
        if (trimmedName.Length > NameMaxLength)
        {
            return Error.Validation("CatalogTranslation.NameTooLong", $"Name cannot exceed {NameMaxLength} characters ({language.Value}).");
        }

        var trimmedDescription = string.IsNullOrWhiteSpace(description) ? null : description.Trim();
        if (trimmedDescription is { Length: > DescriptionMaxLength })
        {
            return Error.Validation(
                "CatalogTranslation.DescriptionTooLong",
                $"Description cannot exceed {DescriptionMaxLength} characters ({language.Value}).");
        }

        return new CatalogTranslation(language.Value, trimmedName, trimmedDescription);
    }

    internal void CopyTextFrom(CatalogTranslation source)
    {
        Name = source.Name;
        Description = source.Description;
    }
}
