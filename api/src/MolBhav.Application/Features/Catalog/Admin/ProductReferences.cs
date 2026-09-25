using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin;

/// <summary>Cross-aggregate existence checks for a product's sub-category and default unit (friendly errors; FKs are the backstop).</summary>
internal static class ProductReferences
{
    public static async Task<Result> CheckAsync(
        IProcurementCategoryRepository categories,
        IUnitOfMeasureRepository units,
        Guid subCategoryId,
        Guid defaultUnitId,
        CancellationToken cancellationToken)
    {
        if (!await categories.SubCategoryExistsAsync(subCategoryId, cancellationToken))
        {
            return Error.Validation("SubCategory.NotFound", "Sub-category not found.");
        }

        if (!await units.ExistsAsync(defaultUnitId, cancellationToken))
        {
            return Error.Validation("UnitOfMeasure.NotFound", "Default unit not found.");
        }

        return Result.Success();
    }
}
