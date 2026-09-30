using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Support;

namespace MolBhav.Infrastructure.Persistence.Configurations.Support;

internal sealed class SupportTicketConfiguration : IEntityTypeConfiguration<SupportTicket>
{
    public const string TableName = "support_tickets";

    public void Configure(EntityTypeBuilder<SupportTicket> builder)
    {
        builder.ToTable(TableName, Schemas.Support);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(t => t.Category).IsRequired();
        builder.Property(t => t.Subject).HasMaxLength(SupportTicket.SubjectMaxLength).IsRequired();
        builder.Property(t => t.Status).IsRequired();
        builder.Property(t => t.LastActivityAtUtc).IsRequired();

        builder.HasOne<User>().WithMany().HasForeignKey(t => t.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();

        // "My tickets": WHERE user_id = ? ORDER BY last_activity_at_utc DESC — also covers the FK.
        builder.HasIndex(t => new { t.UserId, t.LastActivityAtUtc }).IsDescending(false, true);

        // Admin queue: WHERE status = ? ORDER BY last_activity_at_utc DESC.
        builder.HasIndex(t => new { t.Status, t.LastActivityAtUtc }).IsDescending(false, true);

        // Messages are part of the ticket aggregate — cascade, and SupportTicketRepository loads them with it.
        builder.HasMany(t => t.Messages)
            .WithOne()
            .HasForeignKey(SupportTicketMessageConfiguration.TicketIdProperty)
            .OnDelete(DeleteBehavior.Cascade)
            .IsRequired();
        builder.Navigation(t => t.Messages).HasField("_messages").UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}
