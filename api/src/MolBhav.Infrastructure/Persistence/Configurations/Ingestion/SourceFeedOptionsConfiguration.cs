using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Infrastructure.Persistence.Configurations.Ingestion;

internal sealed class SourceFeedOptionsConfiguration : IEntityTypeConfiguration<SourceFeedOptions>
{
    public const string TableName = "source_feed_options";

    public void Configure(EntityTypeBuilder<SourceFeedOptions> builder)
    {
        builder.ToTable(TableName, Schemas.Ingestion);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(o => o.RefreshedAtUtc).IsRequired();

        // A snapshot that is only ever read and replaced whole, so jsonb beats two child tables (a feed has ~2k markets).
        builder.Property(o => o.Commodities)
            .HasColumnType("jsonb")
            .HasConversion(
                v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                v => JsonSerializer.Deserialize<string[]>(v, (JsonSerializerOptions?)null) ?? Array.Empty<string>(),
                new ValueComparer<IReadOnlyList<string>>(
                    (a, b) => a!.SequenceEqual(b!),
                    v => v.Aggregate(0, (h, s) => HashCode.Combine(h, s)),
                    v => v.ToArray()))
            .IsRequired();

        builder.Property(o => o.Markets)
            .HasColumnType("jsonb")
            .HasConversion(
                v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                v => JsonSerializer.Deserialize<FeedMarket[]>(v, (JsonSerializerOptions?)null) ?? Array.Empty<FeedMarket>(),
                new ValueComparer<IReadOnlyList<FeedMarket>>(
                    (a, b) => a!.SequenceEqual(b!),
                    v => v.Aggregate(0, (h, m) => HashCode.Combine(h, m)),
                    v => v.ToArray()))
            .IsRequired();

        builder.Ignore(o => o.States);

        // Restrict, not cascade: sources are deactivated, never deleted. One row per source.
        builder.HasOne<MolBhav.Domain.Pricing.PriceSource>().WithMany().HasForeignKey(o => o.PriceSourceId).OnDelete(DeleteBehavior.Restrict).IsRequired();
        builder.HasIndex(o => o.PriceSourceId).IsUnique();
    }
}
