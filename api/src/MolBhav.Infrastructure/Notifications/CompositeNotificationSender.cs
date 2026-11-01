using Microsoft.Extensions.DependencyInjection;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Notification;

namespace MolBhav.Infrastructure.Notifications;

/// <summary>
/// Routes each <see cref="NotificationMessage"/> to its channel's sender after checking the user's master switch
/// for that channel. Each channel is registered on its own (keyed by <see cref="NotificationChannel"/>): the real
/// gateway when its credentials are configured, otherwise <see cref="LoggingNotificationSender"/> — so WhatsApp can
/// go live before FCM and vice versa.
/// </summary>
internal sealed class CompositeNotificationSender(
    [FromKeyedServices(NotificationChannel.Push)] INotificationSender push,
    [FromKeyedServices(NotificationChannel.WhatsApp)] INotificationSender whatsApp,
    INotificationPreferencesRepository preferences) : INotificationSender
{
    public async Task<bool> SendAsync(NotificationMessage notification, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(notification);

        var prefs = await preferences.GetByUserIdAsync(notification.UserId, cancellationToken);

        return notification.Channel switch
        {
            NotificationChannel.Push when prefs?.PushEnabled ?? true =>
                await push.SendAsync(notification, cancellationToken),

            // WhatsApp is opt-in: no saved preferences means off.
            NotificationChannel.WhatsApp when prefs?.WhatsAppEnabled ?? false =>
                await whatsApp.SendAsync(notification, cancellationToken),

            // Channel switched off by the user — not a delivery failure.
            _ => true,
        };
    }
}
