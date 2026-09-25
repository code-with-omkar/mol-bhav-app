using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Infrastructure.Persistence.Configurations.Catalog;

internal static class CatalogTranslationMapping
{
    /// <summary>Shadow FK name on every translation table (column name is per table, e.g. <c>product_id</c>).</summary>
    private const string OwnerKey = "OwnerId";

    /// <summary>
    /// Maps a translation collection to its own table keyed (owner id, language) — one name per language per item,
    /// FK-bound to the item, loaded with it (owned types are always included).
    /// </summary>
    public static void OwnsTranslations<TOwner>(
        this EntityTypeBuilder<TOwner> builder,
        Expression<Func<TOwner, IEnumerable<CatalogTranslation>?>> navigation,
        string tableName,
        string ownerKeyColumn,
        bool searchable = false)
        where TOwner : class
    {
        builder.OwnsMany(navigation, translation =>
        {
            translation.ToTable(tableName, Schemas.Catalog);
            translation.WithOwner().HasForeignKey(OwnerKey);

            // Explicit, short: the default "fk_{table}_{principal}_{column}" can exceed PostgreSQL's 63-char identifier
            // limit for these long table names and gets truncated with a '~'.
            translation.OwnedEntityType.FindOwnership()!.SetConstraintName($"fk_{tableName}_owner");
            translation.Property<Guid>(OwnerKey).HasColumnName(ownerKeyColumn);

            translation.Property(t => t.LanguageCode)
                .HasMaxLength(LanguageCode.MaxLength)
                .IsFixedLength()
                .IsRequired();
            translation.Property(t => t.Name).HasMaxLength(CatalogTranslation.NameMaxLength).IsRequired();
            translation.Property(t => t.Description).HasMaxLength(CatalogTranslation.DescriptionMaxLength);

            translation.HasKey(OwnerKey, nameof(CatalogTranslation.LanguageCode));

            if (searchable)
            {
                // Product search is ILIKE '%term%' across languages; a trigram GIN index keeps it index-backed
                // (a B-tree cannot serve a leading wildcard). Requires the pg_trgm extension (see MolBhavDbContext).
                translation.HasIndex(t => t.Name)
                    .HasMethod("gin")
                    .HasOperators("gin_trgm_ops");
            }
        });

        builder.Navigation(navigation!).HasField("_translations").UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}
