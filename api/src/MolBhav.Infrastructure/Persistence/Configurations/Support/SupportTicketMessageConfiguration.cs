using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Support;

namespace MolBhav.Infrastructure.Persistence.Configurations.Support;

internal sealed class SupportTicketMessageConfiguration : IEntityTypeConfiguration<SupportTicketMessage>
{
    public const string TableName = "support_ticket_messages";

    /// <summary>Shadow FK to the owning ticket — the domain entity carries no back-reference.</summary>
    public const string TicketIdProperty = "TicketId";

    public void Configure(EntityTypeBuilder<SupportTicketMessage> builder)
    {
        builder.ToTable(TableName, Schemas.Support);

        builder.HasKey(m => m.Id);
        builder.Property(m => m.Id).ValueGeneratedNever();

        // No concurrency token and no audit columns: a message is written once and never updated.
        builder.Property<Guid>(TicketIdProperty).HasColumnName("ticket_id");

        builder.Property(m => m.AuthorKind).IsRequired();
        builder.Property(m => m.Body).HasMaxLength(SupportTicketMessage.BodyMaxLength).IsRequired();
        builder.Property(m => m.CreatedAtUtc).IsRequired();

        // Restrict: a thread names the admin who answered, who outlives the reply.
        builder.HasOne<User>().WithMany().HasForeignKey(m => m.AuthorUserId).OnDelete(DeleteBehavior.Restrict).IsRequired();

        // Thread order within one ticket; also covers the FK.
        builder.HasIndex(TicketIdProperty, nameof(SupportTicketMessage.CreatedAtUtc));
    }
}
