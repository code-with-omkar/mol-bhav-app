using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Infrastructure.Persistence;

namespace MolBhav.Infrastructure.Billing.Webhooks;

internal sealed class WebhookInboxMessageConfiguration : IEntityTypeConfiguration<WebhookInboxMessage>
{
    /// <summary>Pinned explicitly because the inbox insert and the processor's locking query reference it in raw SQL.</summary>
    public const string TableName = "webhook_inbox";

    public const string QualifiedTableName = Schemas.Billing + "." + TableName;

    public void Configure(EntityTypeBuilder<WebhookInboxMessage> builder)
    {
        builder.ToTable(TableName, Schemas.Billing);

        builder.HasKey(m => m.Id);
        builder.Property(m => m.Id).ValueGeneratedNever();

        builder.Property(m => m.Provider).HasMaxLength(WebhookInboxMessage.ProviderMaxLength).IsRequired();
        builder.Property(m => m.EventId).HasMaxLength(WebhookInboxMessage.EventIdMaxLength).IsRequired();
        builder.Property(m => m.EventType).HasMaxLength(WebhookInboxMessage.EventTypeMaxLength).IsRequired();
        builder.Property(m => m.Payload).HasColumnType("jsonb").IsRequired();
        builder.Property(m => m.ReceivedAtUtc).IsRequired();
        builder.Property(m => m.NextAttemptAtUtc).IsRequired();
        builder.Property(m => m.AttemptCount).IsRequired();
        builder.Property(m => m.LastError).HasMaxLength(WebhookInboxMessage.ErrorMaxLength);

        // Deduplication: the gateway redelivers on timeouts and non-2xx, and the insert relies on
        // ON CONFLICT against exactly this index to turn a redelivery into a no-op.
        builder.HasIndex(m => new { m.Provider, m.EventId }).IsUnique();

        // Partial index: the processor only scans pending rows in due order. Processed and parked rows (nearly all of
        // them over time) are excluded, keeping the index tiny and each poll O(batch).
        builder.HasIndex(m => m.NextAttemptAtUtc)
            .HasFilter("processed_at_utc IS NULL AND parked_at_utc IS NULL");

        // Partial index: parked messages are what operators look at (and what monitoring counts).
        builder.HasIndex(m => m.ParkedAtUtc)
            .HasFilter("parked_at_utc IS NOT NULL");
    }
}
