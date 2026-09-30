using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Market;
using MolBhav.Domain.Pricing;

namespace MolBhav.Infrastructure.Persistence.Configurations.Pricing;

/// <summary>
/// Unified price-record-as-history table (BRD §19 collapsed to one aggregate — see PriceRecord's doc comment).
/// Location is two nullable FKs + a <see cref="LocationKind"/> discriminator rather than one polymorphic FK
/// (Postgres/EF cannot express a conditional FK to one of two different tables cleanly).
/// </summary>
internal sealed class PriceRecordConfiguration : IEntityTypeConfiguration<PriceRecord>
{
    public const string TableName = "price_records";

    public void Configure(EntityTypeBuilder<PriceRecord> builder)
    {
        builder.ToTable(TableName, Schemas.Pricing, t => t.HasCheckConstraint(
            "ck_price_records_location",
            "(location_kind = 'Mandi' AND mandi_id IS NOT NULL AND supplier_id IS NULL) OR " +
            "(location_kind = 'Supplier' AND supplier_id IS NOT NULL AND mandi_id IS NULL)"));

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(r => r.LocationKind).IsRequired();
        builder.Property(r => r.RecordDate).HasColumnType("date").IsRequired();
        builder.Property(r => r.ModalPrice).IsRequired();
        builder.Property(r => r.IsVoided).IsRequired();

        // Referenced reference/aggregate data — all deactivated, never deleted, so Restrict is safe.
        builder.HasOne<Product>().WithMany().HasForeignKey(r => r.ProductId).OnDelete(DeleteBehavior.Restrict).IsRequired();
        builder.HasOne<ProductVariant>().WithMany().HasForeignKey(r => r.VariantId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<UnitOfMeasure>().WithMany().HasForeignKey(r => r.UnitId).OnDelete(DeleteBehavior.Restrict).IsRequired();
        builder.HasOne<Mandi>().WithMany().HasForeignKey(r => r.MandiId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<Supplier>().WithMany().HasForeignKey(r => r.SupplierId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<PriceSource>().WithMany().HasForeignKey(r => r.PriceSourceId).OnDelete(DeleteBehavior.Restrict).IsRequired();

        // Comparison matrix / latest-price lookups: WHERE product_id = ... [AND location_kind/mandi/supplier] ORDER BY record_date DESC.
        builder.HasIndex(r => new { r.ProductId, r.LocationKind, r.RecordDate });
        // Browse-by-mandi/supplier: WHERE mandi_id = ... AND NOT is_voided AND record_date >= ... ORDER BY record_date DESC.
        // Partial (non-voided, location set) keeps them small; the leading column also serves the FK.
        builder.HasIndex(r => new { r.MandiId, r.RecordDate })
            .IsDescending(false, true)
            .HasFilter("mandi_id IS NOT NULL AND NOT is_voided");
        builder.HasIndex(r => new { r.SupplierId, r.RecordDate })
            .IsDescending(false, true)
            .HasFilter("supplier_id IS NOT NULL AND NOT is_voided");
        builder.HasIndex(r => r.PriceSourceId);
        builder.HasIndex(r => r.VariantId);

        // Application-layer duplicate pre-check (see IPriceRecordRepository.DuplicateExistsAsync) — not a unique
        // index, since nullable variant/mandi/supplier columns mean Postgres would treat NULLs as always-distinct.
        builder.HasIndex(r => new { r.ProductId, r.UnitId, r.PriceSourceId, r.RecordDate });
    }
}
