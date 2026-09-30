using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Events;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Identity.Events;
using MolBhav.Domain.Notification;

namespace MolBhav.Application.Features.Notification.SendWelcomeNotification;

/// <summary>The Notification-module handler the doc comment on <see cref="UserRegisteredDomainEvent"/> anticipated.
/// Runs outside <c>UnitOfWorkBehavior</c> (dispatched from the outbox, not through MediatR), so it commits its own unit of work.</summary>
internal sealed class WelcomeNotificationHandler(
    INotificationRepository notifications,
    INotificationSender sender,
    IUnitOfWork unitOfWork,
    TimeProvider timeProvider) : IDomainEventHandler<UserRegisteredDomainEvent>
{
    public async Task HandleAsync(UserRegisteredDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        var notification = NotificationMessage.Create(
            domainEvent.UserId,
            NotificationChannel.Push,
            "Welcome to MolBhav",
            "Your account is ready. Start watching commodity and material prices near you.");

        if (notification.IsFailure)
        {
            return;
        }

        await DispatchAsync.SendAndMarkAsync(notification.Value, sender, timeProvider, cancellationToken);

        notifications.Add(notification.Value);
        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
