using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Catalog;
using MolBhav.Infrastructure.Persistence.Converters;

namespace MolBhav.Infrastructure.Persistence.Configurations.Catalog;

internal sealed class ProductVariantConfiguration : IEntityTypeConfiguration<ProductVariant>
{
    public const string TableName = "product_variants";
    public const string TranslationsTableName = "product_variant_translations";

    public void Configure(EntityTypeBuilder<ProductVariant> builder)
    {
        builder.ToTable(TableName, Schemas.Catalog);

        builder.HasKey(v => v.Id);
        builder.Property(v => v.Id).ValueGeneratedNever();
        builder.HasConcurrencyToken();
        builder.ConfigureAuditing();

        builder.Property(v => v.Code)
            .HasConversion(ValueObjectConverters.CatalogCodeConverter)
            .HasMaxLength(CatalogCode.MaxLength)
            .IsRequired();
        builder.Property(v => v.DisplayOrder).IsRequired();
        builder.Property(v => v.IsActive).IsRequired();

        // Code unique within the product; leading product_id also serves the FK.
        builder.HasIndex(v => new { v.ProductId, v.Code }).IsUnique();

        builder.OwnsTranslations(v => v.Translations, TranslationsTableName, "variant_id");
    }
}
