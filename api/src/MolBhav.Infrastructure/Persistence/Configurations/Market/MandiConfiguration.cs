using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Market;
using MolBhav.Infrastructure.Persistence.Converters;

namespace MolBhav.Infrastructure.Persistence.Configurations.Market;

internal sealed class MandiConfiguration : IEntityTypeConfiguration<Mandi>
{
    public const string TableName = "mandis";

    public void Configure(EntityTypeBuilder<Mandi> builder)
    {
        builder.ToTable(TableName, Schemas.Market);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(m => m.Code)
            .HasConversion(ValueObjectConverters.MarketCodeConverter)
            .HasMaxLength(MarketCode.MaxLength)
            .IsRequired();
        builder.HasIndex(m => m.Code).IsUnique();

        builder.Property(m => m.Name).HasMaxLength(MarketRules.NameMaxLength).IsRequired();
        builder.Property(m => m.IsActive).IsRequired();

        // Districts are deactivated, never deleted, while mandis reference them.
        builder.HasOne<District>()
            .WithMany()
            .HasForeignKey(m => m.DistrictId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired();

        // Mandi list screen: WHERE district_id = ... ORDER BY name — also covers the FK.
        builder.HasIndex(m => new { m.DistrictId, m.Name });
    }
}
