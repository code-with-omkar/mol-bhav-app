using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Notification;

namespace MolBhav.Infrastructure.Persistence.Configurations.Notification;

internal sealed class NotificationPreferencesConfiguration : IEntityTypeConfiguration<NotificationPreferences>
{
    public void Configure(EntityTypeBuilder<NotificationPreferences> builder)
    {
        builder.InSchema(Schemas.Notification);

        // Id == UserId (set in the factory); no separate UserId column.
        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(p => p.PushEnabled).IsRequired();
        builder.Property(p => p.AlertPushEnabled).IsRequired();
        builder.Property(p => p.PriceUpdatePushEnabled).IsRequired();
        builder.Property(p => p.WhatsAppEnabled).IsRequired();
        builder.Property(p => p.AlertWhatsAppEnabled).IsRequired();

        // 1:1 relationship; FK to identity.users via the PK.
        builder.HasOne<User>().WithOne().HasForeignKey<NotificationPreferences>(p => p.Id)
            .OnDelete(DeleteBehavior.Cascade).IsRequired();
    }
}
