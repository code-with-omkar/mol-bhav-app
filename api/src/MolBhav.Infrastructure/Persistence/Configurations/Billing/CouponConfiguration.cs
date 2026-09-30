using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Billing;

namespace MolBhav.Infrastructure.Persistence.Configurations.Billing;

internal sealed class CouponConfiguration : IEntityTypeConfiguration<Coupon>
{
    public const string TableName = "coupons";

    public void Configure(EntityTypeBuilder<Coupon> builder)
    {
        // Enums are stored as their names (global convention), so the checks use 'Percent' / 'Fixed'.
        builder.ToTable(TableName, Schemas.Billing, table =>
        {
            table.HasCheckConstraint("ck_coupons_discount_type", "discount_type IN ('Percent', 'Fixed')");
            table.HasCheckConstraint("ck_coupons_discount_value", "discount_value > 0");
            table.HasCheckConstraint("ck_coupons_percent_range", "discount_type <> 'Percent' OR discount_value BETWEEN 1 AND 100");
            table.HasCheckConstraint("ck_coupons_uses", "uses_count >= 0 AND (max_uses IS NULL OR uses_count <= max_uses)");
            table.HasCheckConstraint("ck_coupons_validity", "valid_to IS NULL OR valid_to > valid_from");
        });

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(c => c.Code).IsRequired().HasMaxLength(Coupon.CodeMaxLength);
        builder.Property(c => c.DiscountType).IsRequired().HasMaxLength(10);
        builder.Property(c => c.DiscountValue).IsRequired();
        builder.Property(c => c.UsesCount).IsRequired();
        builder.Property(c => c.ValidFrom).IsRequired();
        builder.Property(c => c.ApplicablePlanCode).HasMaxLength(Plan.CodeMaxLength);
        builder.Property(c => c.MinAmountPaise).IsRequired();
        builder.Property(c => c.IsActive).IsRequired();

        builder.HasIndex(c => c.Code).IsUnique();
    }
}
