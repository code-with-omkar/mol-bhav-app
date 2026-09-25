using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Catalog;
using MolBhav.Infrastructure.Persistence.Converters;

namespace MolBhav.Infrastructure.Persistence.Configurations.Catalog;

internal sealed class UnitOfMeasureConfiguration : IEntityTypeConfiguration<UnitOfMeasure>
{
    public const string TableName = "units_of_measure";
    public const string TranslationsTableName = "unit_of_measure_translations";

    public void Configure(EntityTypeBuilder<UnitOfMeasure> builder)
    {
        builder.ToTable(TableName, Schemas.Catalog);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(u => u.Code)
            .HasConversion(ValueObjectConverters.CatalogCodeConverter)
            .HasMaxLength(CatalogCode.MaxLength)
            .IsRequired();
        builder.HasIndex(u => u.Code).IsUnique();

        builder.Property(u => u.Symbol).HasMaxLength(UnitOfMeasure.SymbolMaxLength).IsRequired();
        builder.Property(u => u.Dimension).IsRequired();
        builder.Property(u => u.ToBaseFactor).HasPrecision(18, UnitOfMeasure.FactorScale).IsRequired();
        builder.Property(u => u.IsActive).IsRequired();

        builder.OwnsTranslations(u => u.Translations, TranslationsTableName, "unit_id");
    }
}
