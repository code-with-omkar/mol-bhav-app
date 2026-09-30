using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Billing;

namespace MolBhav.Infrastructure.Persistence.Configurations.Billing;

internal sealed class PlanConfiguration : IEntityTypeConfiguration<Plan>
{
    public const string TableName = "plans";

    public void Configure(EntityTypeBuilder<Plan> builder)
    {
        builder.ToTable(TableName, Schemas.Billing);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(p => p.Code).HasMaxLength(Plan.CodeMaxLength).IsRequired();
        builder.Property(p => p.Name).HasMaxLength(Plan.NameMaxLength).IsRequired();
        builder.Property(p => p.Price).HasPrecision(12, 2).IsRequired();
        builder.Property(p => p.Currency).HasMaxLength(3).IsRequired();
        builder.Property(p => p.BillingPeriod).IsRequired();
        builder.Property(p => p.IsActive).IsRequired();

        builder.HasIndex(p => p.Code).IsUnique();
    }
}
