using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Market;
using MolBhav.Infrastructure.Persistence.Converters;

namespace MolBhav.Infrastructure.Persistence.Configurations.Market;

internal sealed class SupplierConfiguration : IEntityTypeConfiguration<Supplier>
{
    public const string TableName = "suppliers";

    public void Configure(EntityTypeBuilder<Supplier> builder)
    {
        builder.ToTable(TableName, Schemas.Market);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(s => s.Code)
            .HasConversion(ValueObjectConverters.MarketCodeConverter)
            .HasMaxLength(MarketCode.MaxLength)
            .IsRequired();
        builder.HasIndex(s => s.Code).IsUnique();

        builder.Property(s => s.Name).HasMaxLength(MarketRules.NameMaxLength).IsRequired();
        builder.Property(s => s.ContactPhone).HasMaxLength(MarketRules.ContactPhoneMaxLength);
        builder.Property(s => s.IsActive).IsRequired();

        // Districts are deactivated, never deleted, while suppliers reference them.
        builder.HasOne<District>()
            .WithMany()
            .HasForeignKey(s => s.DistrictId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired();

        // Supplier list screen: WHERE district_id = ... ORDER BY name — also covers the FK.
        builder.HasIndex(s => new { s.DistrictId, s.Name });
    }
}
