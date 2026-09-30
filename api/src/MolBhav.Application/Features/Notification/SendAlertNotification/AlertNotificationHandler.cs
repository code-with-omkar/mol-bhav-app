using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Events;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Alerting.Events;
using MolBhav.Domain.Notification;

namespace MolBhav.Application.Features.Notification.SendAlertNotification;

/// <summary>Reacts to a triggered price-move alert (BRD §15) by queuing a push notification. Runs outside
/// <c>UnitOfWorkBehavior</c> (dispatched from the outbox, not through MediatR), so it commits its own unit of work.</summary>
internal sealed class AlertNotificationHandler(
    INotificationRepository notifications,
    INotificationSender sender,
    IUnitOfWork unitOfWork,
    TimeProvider timeProvider) : IDomainEventHandler<AlertTriggeredDomainEvent>
{
    public async Task HandleAsync(AlertTriggeredDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        // Read the direction off the move itself — it holds for the price-level types too, where the threshold
        // type says which way the level was crossed but not which way the price went.
        var direction = domainEvent.PercentChange <= 0 ? "dropped" : "spiked";
        var body = $"Price {direction} {Math.Abs(domainEvent.PercentChange):0.##}% — now {domainEvent.NewPrice:0.##} (was {domainEvent.PreviousPrice:0.##}).";

        var notification = NotificationMessage.Create(domainEvent.UserId, NotificationChannel.Push, "Price alert triggered", body);
        if (notification.IsFailure)
        {
            return;
        }

        await DispatchAsync.SendAndMarkAsync(notification.Value, sender, timeProvider, cancellationToken);

        notifications.Add(notification.Value);
        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
