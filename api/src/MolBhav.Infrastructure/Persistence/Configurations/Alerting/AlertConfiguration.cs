using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Alerting;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Market;
using MolBhav.Domain.Pricing;

namespace MolBhav.Infrastructure.Persistence.Configurations.Alerting;

internal sealed class AlertConfiguration : IEntityTypeConfiguration<Alert>
{
    public const string TableName = "alerts";

    public void Configure(EntityTypeBuilder<Alert> builder)
    {
        builder.ToTable(TableName, Schemas.Alerting, t => t.HasCheckConstraint(
            "ck_alerts_location",
            "(location_kind = 'Mandi' AND mandi_id IS NOT NULL AND supplier_id IS NULL) OR " +
            "(location_kind = 'Supplier' AND supplier_id IS NOT NULL AND mandi_id IS NULL)"));

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(a => a.LocationKind).IsRequired();
        builder.Property(a => a.PreviousPrice).IsRequired();
        builder.Property(a => a.NewPrice).IsRequired();
        builder.Property(a => a.PercentChange).HasPrecision(9, 4).IsRequired();
        builder.Property(a => a.ThresholdType).IsRequired();
        builder.Property(a => a.TriggeredAtUtc).IsRequired();
        builder.Property(a => a.IsRead).IsRequired();

        // Restrict, not cascade: an alert is a historical record that must survive the rule being deleted.
        builder.HasOne<AlertRule>().WithMany().HasForeignKey(a => a.AlertRuleId).OnDelete(DeleteBehavior.Restrict).IsRequired();
        builder.HasOne<User>().WithMany().HasForeignKey(a => a.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();
        builder.HasOne<Product>().WithMany().HasForeignKey(a => a.ProductId).OnDelete(DeleteBehavior.Restrict).IsRequired();
        builder.HasOne<ProductVariant>().WithMany().HasForeignKey(a => a.VariantId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<PriceRecord>().WithMany().HasForeignKey(a => a.PriceRecordId).OnDelete(DeleteBehavior.Restrict).IsRequired();
        builder.HasOne<Mandi>().WithMany().HasForeignKey(a => a.MandiId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<Supplier>().WithMany().HasForeignKey(a => a.SupplierId).OnDelete(DeleteBehavior.Restrict);

        // The user's alert inbox, newest first.
        builder.HasIndex(a => new { a.UserId, a.TriggeredAtUtc });
        builder.HasIndex(a => a.AlertRuleId);
    }
}
