using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Market;
using MolBhav.Domain.Procurement;

namespace MolBhav.Infrastructure.Persistence.Configurations.Procurement;

internal sealed class ProcurementRequirementConfiguration : IEntityTypeConfiguration<ProcurementRequirement>
{
    public const string TableName = "procurement_requirements";

    public void Configure(EntityTypeBuilder<ProcurementRequirement> builder)
    {
        builder.ToTable(TableName, Schemas.Procurement);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(r => r.Quantity).HasPrecision(14, 3).IsRequired();
        builder.Property(r => r.TargetPrice).HasPrecision(14, 2);

        builder.HasOne<User>().WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();
        builder.HasOne<Product>().WithMany().HasForeignKey(r => r.ProductId).OnDelete(DeleteBehavior.Restrict).IsRequired();
        builder.HasOne<ProductVariant>().WithMany().HasForeignKey(r => r.VariantId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<UnitOfMeasure>().WithMany().HasForeignKey(r => r.UnitId).OnDelete(DeleteBehavior.Restrict).IsRequired();
        builder.HasOne<District>().WithMany().HasForeignKey(r => r.TargetDistrictId).OnDelete(DeleteBehavior.Restrict);

        // The user's own requirement list.
        builder.HasIndex(r => r.UserId);
    }
}
