using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Catalog;

/// <summary>Rules shared by every orderable catalog item.</summary>
public static class CatalogRules
{
    public const int MaxDisplayOrder = 10_000;

    public static Result ValidateDisplayOrder(int displayOrder) =>
        displayOrder is >= 0 and <= MaxDisplayOrder
            ? Result.Success()
            : Error.Validation("Catalog.InvalidDisplayOrder", $"Display order must be between 0 and {MaxDisplayOrder}.");

    /// <summary>Display order in range and a valid translation set (English present, one entry per language).</summary>
    internal static Result ValidateItem(int displayOrder, IReadOnlyCollection<CatalogTranslation> translations)
    {
        var order = ValidateDisplayOrder(displayOrder);
        return order.IsFailure ? order : CatalogTranslations.Validate(translations);
    }
}
