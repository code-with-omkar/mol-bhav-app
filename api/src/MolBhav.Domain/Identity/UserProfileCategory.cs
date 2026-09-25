using MolBhav.Domain.SharedKernel;

namespace MolBhav.Domain.Identity;

/// <summary>
/// One procurement category a user operates in (BRD §7 "one or more procurement categories"). Modelled as an owned
/// collection element keyed by (user, category code), FK-bound to the catalog category.
/// </summary>
public sealed class UserProfileCategory
{
    private UserProfileCategory(ProcurementCategoryCode categoryCode) => CategoryCode = categoryCode;

    /// <summary>Required by EF Core for materialisation.</summary>
    private UserProfileCategory() => CategoryCode = null!;

    /// <summary>References a catalog category by its code (FK to <c>catalog.procurement_categories.code</c>).</summary>
    public ProcurementCategoryCode CategoryCode { get; private init; }

    internal static UserProfileCategory For(ProcurementCategoryCode categoryCode)
    {
        ArgumentNullException.ThrowIfNull(categoryCode);
        return new UserProfileCategory(categoryCode);
    }
}
