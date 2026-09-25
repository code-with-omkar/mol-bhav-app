using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Infrastructure.Persistence;

namespace MolBhav.Infrastructure.Messaging.Outbox;

internal sealed class OutboxMessageConfiguration : IEntityTypeConfiguration<OutboxMessage>
{
    /// <summary>Pinned explicitly because the processor's locking query references it in raw SQL.</summary>
    public const string TableName = "outbox_messages";

    public const string QualifiedTableName = Schemas.Messaging + "." + TableName;

    public void Configure(EntityTypeBuilder<OutboxMessage> builder)
    {
        builder.ToTable(TableName, Schemas.Messaging);

        builder.HasKey(m => m.Id);
        builder.Property(m => m.Id).ValueGeneratedNever();

        builder.Property(m => m.OccurredAtUtc).IsRequired();
        builder.Property(m => m.Type).HasMaxLength(OutboxMessage.TypeMaxLength).IsRequired();
        builder.Property(m => m.Content).HasColumnType("jsonb").IsRequired();
        builder.Property(m => m.AttemptCount).IsRequired();
        builder.Property(m => m.LastError).HasMaxLength(OutboxMessage.ErrorMaxLength);

        // Partial index: the processor only ever scans unprocessed rows in occurrence order.
        // Processed rows (the vast majority over time) are excluded, keeping the index tiny and the poll O(batch).
        builder.HasIndex(m => m.OccurredAtUtc)
            .HasFilter("processed_at_utc IS NULL");
    }
}
