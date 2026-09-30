using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Notification;

namespace MolBhav.Application.Features.Notification;

/// <summary>Shared send-then-mark logic for every domain-event handler that creates a <see cref="NotificationMessage"/>.</summary>
internal static class DispatchAsync
{
    public static async Task SendAndMarkAsync(
        NotificationMessage notification, INotificationSender sender, TimeProvider timeProvider, CancellationToken cancellationToken)
    {
        try
        {
            var sent = await sender.SendAsync(notification, cancellationToken);
            if (sent)
            {
                notification.MarkSent(timeProvider.GetUtcNow());
            }
            else
            {
                notification.MarkFailed("Sender reported failure.");
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            notification.MarkFailed(ex.Message);
        }
    }
}
