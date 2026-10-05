using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Pricing.Admin.Common;

/// <summary>Turns the category code an admin sends into the id of an active category — shared by create and update.</summary>
internal static class PriceSourceCategoryResolver
{
    public static async Task<Result<Guid>> ResolveAsync(
        IProcurementCategoryRepository categories, string? categoryCode, CancellationToken cancellationToken)
    {
        var code = ProcurementCategoryCode.Create(categoryCode);
        if (code.IsFailure)
        {
            return Result.Failure<Guid>(code.Error);
        }

        var id = await categories.GetActiveIdByCodeAsync(code.Value, cancellationToken);
        if (id is null)
        {
            return Error.Validation("PriceSource.CategoryNotFound", $"No active category with code '{code.Value.Value}'.");
        }

        return id.Value;
    }
}
