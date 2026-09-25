using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.SharedKernel;
using MolBhav.Infrastructure.Persistence.Converters;

namespace MolBhav.Infrastructure.Persistence.Configurations.Catalog;

internal sealed class ProcurementCategoryConfiguration : IEntityTypeConfiguration<ProcurementCategory>
{
    public const string TableName = "procurement_categories";
    public const string TranslationsTableName = "procurement_category_translations";

    public void Configure(EntityTypeBuilder<ProcurementCategory> builder)
    {
        builder.ToTable(TableName, Schemas.Catalog);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(c => c.Code)
            .HasConversion(ValueObjectConverters.ProcurementCategoryCodeConverter)
            .HasMaxLength(ProcurementCategoryCode.MaxLength)
            .IsRequired();

        // Alternate key (unique constraint), not just a unique index: other modules reference categories by code
        // (identity.user_categories today; watchlists/alerts later), so it must be a valid FK target.
        builder.HasAlternateKey(c => c.Code);

        builder.Property(c => c.IconKey).HasMaxLength(ProcurementCategory.IconKeyMaxLength);
        builder.Property(c => c.DisplayOrder).IsRequired();
        builder.Property(c => c.IsActive).IsRequired();

        builder.OwnsTranslations(c => c.Translations, TranslationsTableName, "category_id");

        builder.HasMany(c => c.SubCategories)
            .WithOne()
            .HasForeignKey(s => s.CategoryId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired();
        builder.Navigation(c => c.SubCategories).HasField("_subCategories").UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}
