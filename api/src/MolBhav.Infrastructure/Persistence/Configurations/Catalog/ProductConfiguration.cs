using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Catalog;
using MolBhav.Infrastructure.Persistence.Converters;

namespace MolBhav.Infrastructure.Persistence.Configurations.Catalog;

internal sealed class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public const string TableName = "products";
    public const string TranslationsTableName = "product_translations";

    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable(TableName, Schemas.Catalog);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(p => p.Code)
            .HasConversion(ValueObjectConverters.CatalogCodeConverter)
            .HasMaxLength(CatalogCode.MaxLength)
            .IsRequired();
        builder.HasIndex(p => p.Code).IsUnique();

        builder.Property(p => p.DisplayOrder).IsRequired();
        builder.Property(p => p.IsActive).IsRequired();
        builder.Property(p => p.ImageKey).HasMaxLength(Product.ImageKeyMaxLength);

        // Restrict: sub-categories and units are deactivated, never deleted, while products reference them.
        builder.HasOne<SubCategory>()
            .WithMany()
            .HasForeignKey(p => p.SubCategoryId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired();

        builder.HasOne<UnitOfMeasure>()
            .WithMany()
            .HasForeignKey(p => p.DefaultUnitId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired();

        // Product list screen: WHERE sub_category_id IN (...) ORDER BY display_order — also covers the FK.
        builder.HasIndex(p => new { p.SubCategoryId, p.DisplayOrder });
        builder.HasIndex(p => p.DefaultUnitId);

        builder.OwnsTranslations(p => p.Translations, TranslationsTableName, "product_id", searchable: true);

        builder.HasMany(p => p.Variants)
            .WithOne()
            .HasForeignKey(v => v.ProductId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired();
        builder.Navigation(p => p.Variants).HasField("_variants").UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}
