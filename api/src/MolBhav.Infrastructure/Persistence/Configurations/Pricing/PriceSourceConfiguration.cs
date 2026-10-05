using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Pricing;

namespace MolBhav.Infrastructure.Persistence.Configurations.Pricing;

internal sealed class PriceSourceConfiguration : IEntityTypeConfiguration<PriceSource>
{
    public const string TableName = "price_sources";

    public void Configure(EntityTypeBuilder<PriceSource> builder)
    {
        builder.ToTable(TableName, Schemas.Pricing);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(s => s.Code).HasMaxLength(PricingRules.SourceCodeMaxLength).IsRequired();
        builder.HasIndex(s => s.Code).IsUnique();

        builder.Property(s => s.Name).HasMaxLength(PricingRules.SourceNameMaxLength).IsRequired();
        builder.Property(s => s.IsActive).IsRequired();

        builder.HasOne<ProcurementCategory>().WithMany().HasForeignKey(s => s.CategoryId).OnDelete(DeleteBehavior.Restrict).IsRequired();

        // FK index; also serves the admin "sources of category X" filter and the category run-all lookup.
        builder.HasIndex(s => s.CategoryId);
    }
}
