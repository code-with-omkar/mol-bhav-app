namespace MolBhav.Domain.Identity;

/// <summary>
/// Entitlement tier (BRD §7/§23). Kept as a Domain concept because <see cref="User"/> owns it; the Billing module
/// (Plans/Subscriptions/Entitlements) will own richer subscription lifecycle state once it exists — this is the
/// coarse flag every request needs today (JWT claim, [pro-subscriber] policy).
/// </summary>
public enum SubscriptionTier
{
    Free = 0,
    Pro = 1,
}
