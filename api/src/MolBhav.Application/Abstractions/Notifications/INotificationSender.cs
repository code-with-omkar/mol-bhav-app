using MolBhav.Domain.Notification;

namespace MolBhav.Application.Abstractions.Notifications;

/// <summary>
/// Dispatches one <see cref="NotificationMessage"/> over its channel. Until a real WhatsApp/push gateway is
/// contracted, the registered implementation only logs the content and reports failure (see
/// <c>LoggingNotificationSender</c>) — callers still persist the attempt via <see cref="Domain.Notification.NotificationStatus"/> either way.
/// </summary>
public interface INotificationSender
{
    Task<bool> SendAsync(NotificationMessage notification, CancellationToken cancellationToken = default);
}
