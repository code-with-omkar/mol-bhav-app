using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Identity;

namespace MolBhav.Infrastructure.Persistence.Configurations.Billing;

internal sealed class SubscriptionConfiguration : IEntityTypeConfiguration<Subscription>
{
    public const string TableName = "subscriptions";

    public void Configure(EntityTypeBuilder<Subscription> builder)
    {
        builder.ToTable(TableName, Schemas.Billing, table =>
        {
            table.HasCheckConstraint("ck_subscriptions_amounts", "amount_paise >= 0 AND discount_paise >= 0 AND discount_paise <= amount_paise");
        });

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(s => s.Status).IsRequired();
        // Defaults backfill rows that predate these columns; new rows always carry explicit values.
        builder.Property(s => s.BillingCycle).IsRequired().HasMaxLength(10).HasDefaultValue(BillingPeriod.Monthly).HasSentinel(BillingPeriod.Monthly);
        builder.Property(s => s.Currency).IsRequired().HasMaxLength(3).HasDefaultValue(Subscription.DefaultCurrency);
        builder.Property(s => s.StartedAtUtc).IsRequired();
        builder.Property(s => s.ExpiresAtUtc).IsRequired();
        builder.Property(s => s.IsAutoRenew).IsRequired();
        builder.Property(s => s.AmountPaise).IsRequired();
        builder.Property(s => s.DiscountPaise).IsRequired();

        builder.Property(s => s.RazorpayOrderId).HasMaxLength(50);
        builder.Property(s => s.RazorpayPaymentId).HasMaxLength(50);
        builder.Property(s => s.RazorpaySignature).HasMaxLength(512);
        builder.Property(s => s.CouponCode).HasMaxLength(Coupon.CodeMaxLength);

        builder.HasOne<User>().WithMany().HasForeignKey(s => s.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();
        builder.HasOne<Plan>().WithMany().HasForeignKey(s => s.PlanId).OnDelete(DeleteBehavior.Restrict).IsRequired();

        // "Does this user already have an active subscription?" + the user's billing history.
        builder.HasIndex(s => new { s.UserId, s.Status });

        // Activation looks subscriptions up by order; uniqueness also stops one payment activating two subscriptions.
        builder.HasIndex(s => s.RazorpayOrderId).IsUnique().HasFilter("razorpay_order_id IS NOT NULL");
        builder.HasIndex(s => s.RazorpayPaymentId).IsUnique().HasFilter("razorpay_payment_id IS NOT NULL");

        // The expiry sweep asks "which Active subscriptions have lapsed?" every few minutes. Only Active rows
        // (SubscriptionStatus.Active, stored as text) are indexed, so the index stays tiny however much billing history piles up.
        builder.HasIndex(s => s.ExpiresAtUtc).HasDatabaseName("ix_subscriptions_active_expires_at_utc").HasFilter("status = 'Active'");
    }
}
