using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Alerting;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Market;

namespace MolBhav.Infrastructure.Persistence.Configurations.Alerting;

internal sealed class AlertRuleConfiguration : IEntityTypeConfiguration<AlertRule>
{
    public const string TableName = "alert_rules";

    public void Configure(EntityTypeBuilder<AlertRule> builder)
    {
        builder.ToTable(TableName, Schemas.Alerting, t =>
        {
            t.HasCheckConstraint(
                "ck_alert_rules_location",
                "(location_kind IS NULL AND mandi_id IS NULL AND supplier_id IS NULL) OR " +
                "(location_kind = 'Mandi' AND mandi_id IS NOT NULL AND supplier_id IS NULL) OR " +
                "(location_kind = 'Supplier' AND supplier_id IS NOT NULL AND mandi_id IS NULL)");

            // Mirrors AlertRule.ValidateThreshold: a percent type carries exactly a percent, a price type exactly a price.
            t.HasCheckConstraint(
                "ck_alert_rules_threshold",
                "(threshold_type IN ('PriceDrop', 'PriceSpike', 'PriceChange') AND threshold_percent IS NOT NULL AND threshold_price IS NULL) OR " +
                "(threshold_type IN ('PriceBelow', 'PriceAbove') AND threshold_price IS NOT NULL AND threshold_percent IS NULL)");
        });

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(r => r.LocationKind);
        builder.Property(r => r.ThresholdType).IsRequired();
        builder.Property(r => r.ThresholdPercent).HasPrecision(5, 2);
        builder.Property(r => r.ThresholdPrice).HasPrecision(14, 2);
        builder.Property(r => r.IsActive).IsRequired();

        builder.HasOne<User>().WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();
        builder.HasOne<Product>().WithMany().HasForeignKey(r => r.ProductId).OnDelete(DeleteBehavior.Restrict).IsRequired();
        builder.HasOne<ProductVariant>().WithMany().HasForeignKey(r => r.VariantId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<Mandi>().WithMany().HasForeignKey(r => r.MandiId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<Supplier>().WithMany().HasForeignKey(r => r.SupplierId).OnDelete(DeleteBehavior.Restrict);

        // The user's own rule list.
        builder.HasIndex(r => r.UserId);

        // Evaluation lookup: every active rule for a product, filtered/matched in memory (see EvaluateAlertRulesHandler).
        builder.HasIndex(r => new { r.ProductId, r.IsActive });
    }
}
