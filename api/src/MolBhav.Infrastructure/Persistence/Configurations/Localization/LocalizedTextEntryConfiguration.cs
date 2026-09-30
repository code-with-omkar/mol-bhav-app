using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Localization;
using MolBhav.Infrastructure.Persistence.Converters;

namespace MolBhav.Infrastructure.Persistence.Configurations.Localization;

internal sealed class LocalizedTextEntryConfiguration : IEntityTypeConfiguration<LocalizedTextEntry>
{
    public const string TableName = "localized_text_entries";
    public const string TranslationsTableName = "localized_text_values";

    public void Configure(EntityTypeBuilder<LocalizedTextEntry> builder)
    {
        builder.ToTable(TableName, Schemas.Localization);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(e => e.Key)
            .HasConversion(ValueObjectConverters.LocalizationKeyConverter)
            .HasMaxLength(LocalizationKey.MaxLength)
            .IsRequired();

        // Alternate key: other modules will look strings up by key (never by id), so it must stay unique.
        builder.HasAlternateKey(e => e.Key);

        builder.Property(e => e.Description).HasMaxLength(LocalizedTextEntry.DescriptionMaxLength);

        builder.OwnsLocalizedTextValues(e => e.Translations, TranslationsTableName, "text_entry_id");
    }
}
