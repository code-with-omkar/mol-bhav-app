using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Notification;

namespace MolBhav.Infrastructure.Notifications;

/// <summary>
/// Routes each <see cref="NotificationMessage"/> to the right channel sender after checking the user's preferences.
/// Replaces <see cref="LoggingNotificationSender"/> once FCM and WhatsApp are configured.
/// </summary>
internal sealed class CompositeNotificationSender(
    FcmPushSender fcm,
    WhatsAppCloudSender whatsApp,
    INotificationPreferencesRepository preferences) : INotificationSender
{
    public async Task<bool> SendAsync(NotificationMessage notification, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(notification);

        var prefs = await preferences.GetByUserIdAsync(notification.UserId, cancellationToken);

        return notification.Channel switch
        {
            NotificationChannel.Push when prefs?.PushEnabled ?? true =>
                await fcm.SendAsync(notification, cancellationToken),

            NotificationChannel.WhatsApp when prefs?.WhatsAppEnabled ?? true =>
                await whatsApp.SendAsync(notification, cancellationToken),

            // Channel disabled by user preferences — not a delivery failure.
            _ => true,
        };
    }
}
