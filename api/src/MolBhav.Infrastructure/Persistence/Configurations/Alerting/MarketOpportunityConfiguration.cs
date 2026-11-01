using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Alerting;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Market;

namespace MolBhav.Infrastructure.Persistence.Configurations.Alerting;

internal sealed class MarketOpportunityConfiguration : IEntityTypeConfiguration<MarketOpportunity>
{
    public const string TableName = "market_opportunities";

    public void Configure(EntityTypeBuilder<MarketOpportunity> builder)
    {
        builder.ToTable(TableName, Schemas.Alerting, t =>
        {
            t.HasCheckConstraint(
                "ck_market_opportunities_home_location",
                "(home_location_kind = 'Mandi' AND home_mandi_id IS NOT NULL AND home_supplier_id IS NULL) OR " +
                "(home_location_kind = 'Supplier' AND home_supplier_id IS NOT NULL AND home_mandi_id IS NULL)");
            t.HasCheckConstraint(
                "ck_market_opportunities_best_location",
                "(best_location_kind = 'Mandi' AND best_mandi_id IS NOT NULL AND best_supplier_id IS NULL) OR " +
                "(best_location_kind = 'Supplier' AND best_supplier_id IS NOT NULL AND best_mandi_id IS NULL)");
            t.HasCheckConstraint(
                "ck_market_opportunities_prices",
                "home_price > 0 AND best_price > 0 AND landed_price >= best_price AND landed_price < home_price");
        });

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Ignore(o => o.SavingsPerUnit);

        builder.Property(o => o.DetectedOn).IsRequired();
        builder.Property(o => o.HomeLocationKind).IsRequired();
        builder.Property(o => o.HomePrice).IsRequired();
        builder.Property(o => o.BestLocationKind).IsRequired();
        builder.Property(o => o.BestPrice).IsRequired();
        builder.Property(o => o.LandedPrice).IsRequired();
        builder.Property(o => o.SavingsPercent).HasPrecision(9, 4).IsRequired();
        builder.Property(o => o.PriceDate).IsRequired();
        builder.Property(o => o.DetectedAtUtc).IsRequired();
        builder.Property(o => o.IsRead).IsRequired();

        builder.HasOne<User>().WithMany().HasForeignKey(o => o.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();
        builder.HasOne<Product>().WithMany().HasForeignKey(o => o.ProductId).OnDelete(DeleteBehavior.Restrict).IsRequired();
        builder.HasOne<ProductVariant>().WithMany().HasForeignKey(o => o.VariantId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<Mandi>().WithMany().HasForeignKey(o => o.HomeMandiId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<Supplier>().WithMany().HasForeignKey(o => o.HomeSupplierId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<Mandi>().WithMany().HasForeignKey(o => o.BestMandiId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<Supplier>().WithMany().HasForeignKey(o => o.BestSupplierId).OnDelete(DeleteBehavior.Restrict);

        // Once a day per user and product; also serves the scan's "already found today" lookup by date.
        builder.HasIndex(o => new { o.DetectedOn, o.UserId, o.ProductId }).IsUnique();

        // The user's list, newest first.
        builder.HasIndex(o => new { o.UserId, o.DetectedAtUtc });

        // FK lookups (restrict deletes check these).
        builder.HasIndex(o => o.ProductId);
        builder.HasIndex(o => o.VariantId);
        builder.HasIndex(o => o.HomeMandiId);
        builder.HasIndex(o => o.HomeSupplierId);
        builder.HasIndex(o => o.BestMandiId);
        builder.HasIndex(o => o.BestSupplierId);
    }
}
