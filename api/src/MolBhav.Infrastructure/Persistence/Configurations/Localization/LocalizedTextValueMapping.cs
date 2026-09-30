using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Localization;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Infrastructure.Persistence.Configurations.Localization;

internal static class LocalizedTextValueMapping
{
    /// <summary>Shadow FK name on the translation table.</summary>
    private const string OwnerKey = "OwnerId";

    /// <summary>
    /// Maps a <see cref="LocalizedTextValue"/> collection to its own table keyed (owner id, language) — mirrors
    /// <c>Catalog.CatalogTranslationMapping.OwnsTranslations</c> for the generic localization store.
    /// </summary>
    public static void OwnsLocalizedTextValues<TOwner>(
        this EntityTypeBuilder<TOwner> builder,
        Expression<Func<TOwner, IEnumerable<LocalizedTextValue>?>> navigation,
        string tableName,
        string ownerKeyColumn)
        where TOwner : class
    {
        builder.OwnsMany(navigation, translation =>
        {
            translation.ToTable(tableName, Schemas.Localization);
            translation.WithOwner().HasForeignKey(OwnerKey);
            translation.OwnedEntityType.FindOwnership()!.SetConstraintName($"fk_{tableName}_owner");
            translation.Property<Guid>(OwnerKey).HasColumnName(ownerKeyColumn);

            translation.Property(t => t.LanguageCode)
                .HasMaxLength(LanguageCode.MaxLength)
                .IsFixedLength()
                .IsRequired();
            translation.Property(t => t.Text).HasMaxLength(LocalizedTextValue.TextMaxLength).IsRequired();

            translation.HasKey(OwnerKey, nameof(LocalizedTextValue.LanguageCode));
        });

        builder.Navigation(navigation!).HasField("_translations").UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}
