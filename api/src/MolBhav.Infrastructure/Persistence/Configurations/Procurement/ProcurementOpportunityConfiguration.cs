using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Procurement;

namespace MolBhav.Infrastructure.Persistence.Configurations.Procurement;

internal sealed class ProcurementOpportunityConfiguration : IEntityTypeConfiguration<ProcurementOpportunity>
{
    public const string TableName = "procurement_opportunities";

    public void Configure(EntityTypeBuilder<ProcurementOpportunity> builder)
    {
        builder.ToTable(TableName, Schemas.Procurement);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(o => o.LocationKind).IsRequired();
        builder.Property(o => o.LocationName).HasMaxLength(200).IsRequired();
        builder.Property(o => o.Quantity).HasPrecision(14, 3).IsRequired();
        builder.Property(o => o.UnitPrice).HasPrecision(14, 2).IsRequired();
        builder.Property(o => o.EstimatedCost).HasPrecision(16, 2).IsRequired();
        builder.Property(o => o.SavingsVsTarget).HasPrecision(16, 2);
        builder.Property(o => o.PriceRecordDate).HasColumnType("date").IsRequired();
        builder.Property(o => o.ComputedAtUtc).IsRequired();

        // No FK to mandi/supplier: LocationId/LocationName are a denormalized snapshot (see the aggregate's doc
        // comment) — the location row referenced at compute time may since have changed or been deactivated.
        builder.HasOne<ProcurementRequirement>().WithMany().HasForeignKey(o => o.RequirementId).OnDelete(DeleteBehavior.Cascade).IsRequired();

        // The requirement's opportunity list, cheapest first.
        builder.HasIndex(o => new { o.RequirementId, o.EstimatedCost });
    }
}
