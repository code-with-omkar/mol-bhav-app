using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Market;

namespace MolBhav.Infrastructure.Persistence.Configurations.Market;

internal sealed class DistrictConfiguration : IEntityTypeConfiguration<District>
{
    public const string TableName = "districts";

    public void Configure(EntityTypeBuilder<District> builder)
    {
        builder.ToTable(TableName, Schemas.Market);

        builder.HasKey(d => d.Id);
        builder.Property(d => d.Id).ValueGeneratedNever();
        builder.HasConcurrencyToken();
        builder.ConfigureAuditing();

        builder.Property(d => d.Name).HasMaxLength(MarketRules.DistrictNameMaxLength).IsRequired();
        builder.Property(d => d.IsActive).IsRequired();

        // Districts screen for a state; also covers the FK.
        builder.HasIndex(d => new { d.StateId, d.Name }).IsUnique();
    }
}
