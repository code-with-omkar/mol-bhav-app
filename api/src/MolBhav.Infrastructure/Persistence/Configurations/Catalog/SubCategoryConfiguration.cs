using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Catalog;
using MolBhav.Infrastructure.Persistence.Converters;

namespace MolBhav.Infrastructure.Persistence.Configurations.Catalog;

internal sealed class SubCategoryConfiguration : IEntityTypeConfiguration<SubCategory>
{
    public const string TableName = "sub_categories";
    public const string TranslationsTableName = "sub_category_translations";

    public void Configure(EntityTypeBuilder<SubCategory> builder)
    {
        builder.ToTable(TableName, Schemas.Catalog);

        builder.HasKey(s => s.Id);
        builder.Property(s => s.Id).ValueGeneratedNever();

        // Child rows live in their own table, so the root's xmin does not cover them: each row carries its own token.
        builder.HasConcurrencyToken();
        builder.ConfigureAuditing();

        builder.Property(s => s.Code)
            .HasConversion(ValueObjectConverters.CatalogCodeConverter)
            .HasMaxLength(CatalogCode.MaxLength)
            .IsRequired();
        builder.Property(s => s.DisplayOrder).IsRequired();
        builder.Property(s => s.IsActive).IsRequired();

        // Code unique within the category; the leading category_id column also serves the FK.
        builder.HasIndex(s => new { s.CategoryId, s.Code }).IsUnique();

        builder.OwnsTranslations(s => s.Translations, TranslationsTableName, "sub_category_id");
    }
}
