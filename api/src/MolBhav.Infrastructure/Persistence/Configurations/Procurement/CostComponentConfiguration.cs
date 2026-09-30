using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Procurement;

namespace MolBhav.Infrastructure.Persistence.Configurations.Procurement;

internal sealed class CostComponentConfiguration : IEntityTypeConfiguration<CostComponent>
{
    public const string TableName = "cost_components";

    public void Configure(EntityTypeBuilder<CostComponent> builder)
    {
        builder.ToTable(TableName, Schemas.Procurement);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(c => c.Code).HasMaxLength(CostComponent.CodeMaxLength).IsRequired();
        builder.Property(c => c.Name).HasMaxLength(CostComponent.NameMaxLength).IsRequired();
        builder.Property(c => c.ComponentType).IsRequired();
        builder.Property(c => c.Value).HasPrecision(12, 4).IsRequired();
        builder.Property(c => c.IsActive).IsRequired();

        builder.HasIndex(c => c.Code).IsUnique();
    }
}
