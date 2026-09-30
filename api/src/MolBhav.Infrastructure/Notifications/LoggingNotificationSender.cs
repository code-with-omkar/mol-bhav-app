using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Notification;

namespace MolBhav.Infrastructure.Notifications;

/// <summary>
/// Stand-in <see cref="INotificationSender"/> until a WhatsApp/push gateway is contracted (data model + admin CRUD
/// only, per scope): logs the content and reports success so the domain-event pipeline (outbox → handler →
/// notification row) can be exercised end-to-end. Swap this registration for a real gateway client in
/// <c>DependencyInjection.AddNotificationModule</c> when one is available.
/// </summary>
internal sealed partial class LoggingNotificationSender(ILogger<LoggingNotificationSender> logger) : INotificationSender
{
    public Task<bool> SendAsync(NotificationMessage notification, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(notification);

        LogNotification(logger, notification.Channel, notification.UserId, notification.Title, notification.Body);
        return Task.FromResult(true);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "[STUB {Channel} NOTIFICATION] To user {UserId}: {Title} — {Body}")]
    private static partial void LogNotification(ILogger logger, NotificationChannel channel, Guid userId, string title, string body);
}
