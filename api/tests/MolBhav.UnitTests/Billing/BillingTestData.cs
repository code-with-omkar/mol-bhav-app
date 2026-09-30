using MolBhav.Domain.Billing;

namespace MolBhav.UnitTests.Billing;

internal sealed class FixedTimeProvider(DateTimeOffset now) : TimeProvider
{
    public override DateTimeOffset GetUtcNow() => now;
}

internal static class BillingTestData
{
    public static readonly DateTimeOffset Now = new(2026, 9, 28, 10, 0, 0, TimeSpan.Zero);

    public static Plan ProMonthly(decimal price = 499m) =>
        Plan.Create("pro-monthly", "Pro", price, "INR", BillingPeriod.Monthly).Value;

    public static Subscription Pending(Guid userId, Plan plan, string? couponCode = null, long discountPaise = 0, string orderId = "order_1")
    {
        var subscription = Subscription.Create(userId, plan.Id, plan.BillingPeriod, plan.PricePaise, "INR", couponCode, discountPaise).Value;
        subscription.AttachGatewayOrder(orderId);
        return subscription;
    }

    public static Subscription Active(Guid userId, Plan plan, DateTimeOffset activatedAt)
    {
        var subscription = Pending(userId, plan, orderId: $"order_{Guid.NewGuid():N}");
        subscription.Activate($"pay_{Guid.NewGuid():N}", "sig", activatedAt);
        return subscription;
    }

    public static Coupon Coupon(
        DiscountType type = DiscountType.Percent,
        long value = 10,
        int? maxUses = null,
        DateTimeOffset? validFrom = null,
        DateTimeOffset? validTo = null,
        string? planCode = null,
        long minAmountPaise = 0) =>
        Domain.Billing.Coupon.Create("launch50", type, value, maxUses, validFrom ?? Now.AddDays(-1), validTo, planCode, minAmountPaise).Value;

    /// <summary>Usage only ever changes in the database (atomic UPDATE); tests set it the way EF would.</summary>
    public static Coupon WithUses(this Coupon coupon, int uses)
    {
        typeof(Coupon).GetProperty(nameof(Domain.Billing.Coupon.UsesCount))!.SetValue(coupon, uses);
        return coupon;
    }
}
