using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Notification;

namespace MolBhav.Infrastructure.Persistence.Configurations.Notification;

internal sealed class NotificationMessageConfiguration : IEntityTypeConfiguration<NotificationMessage>
{
    public const string TableName = "notifications";

    public void Configure(EntityTypeBuilder<NotificationMessage> builder)
    {
        builder.ToTable(TableName, Schemas.Notification);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(n => n.Channel).IsRequired();
        builder.Property(n => n.Title).HasMaxLength(NotificationMessage.TitleMaxLength).IsRequired();
        builder.Property(n => n.Body).HasMaxLength(NotificationMessage.BodyMaxLength).IsRequired();
        builder.Property(n => n.Status).IsRequired();
        builder.Property(n => n.FailureReason).HasMaxLength(500);

        builder.HasOne<User>().WithMany().HasForeignKey(n => n.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();

        // The user's inbox, newest first; admin monitoring filters by status/channel.
        builder.HasIndex(n => new { n.UserId, n.CreatedAtUtc });
        builder.HasIndex(n => n.Status);
    }
}
