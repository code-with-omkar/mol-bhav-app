namespace MolBhav.Domain.Identity;

/// <summary>
/// Onboarding/profile data (BRD §7): business type and operating region. A value-object-like child owned entirely
/// by <see cref="User"/> — no identity of its own, mutated only through the aggregate root. Mapped into the same
/// <c>identity.users</c> table as its owner (table-split owned type). Procurement categories are a genuine
/// one-to-many, so they live directly on <see cref="User"/> (<see cref="User.Categories"/>) with their own table,
/// rather than nested a second level inside this owned type.
/// </summary>
public sealed class UserProfile
{
    public const int FieldMaxLength = 100;

    internal UserProfile()
    {
    }

    /// <summary>E.g. Cloud Kitchen, Caterer, Retail Trader (agriculture) or General Civil Contractor, Interior Decorator (construction) — BRD §7. Free-form until the Catalog module owns a controlled list per category.</summary>
    public string? BusinessType { get; private set; }

    /// <summary>Operating region/state (BRD §7). Free text until the Market module's location master exists.</summary>
    public string? State { get; private set; }

    public string? District { get; private set; }

    internal void Update(string? businessType, string? state, string? district)
    {
        BusinessType = Normalise(businessType);
        State = Normalise(state);
        District = Normalise(district);
    }

    private static string? Normalise(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var trimmed = value.Trim();
        return trimmed.Length > FieldMaxLength ? trimmed[..FieldMaxLength] : trimmed;
    }
}
