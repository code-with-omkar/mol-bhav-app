using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Notification;

namespace MolBhav.Application.Abstractions.Notifications;

public interface INotificationRepository : IRepository<NotificationMessage, Guid>
{
    /// <summary>The notification the gateway accepted under this id (WhatsApp <c>wamid</c>), if any.</summary>
    Task<NotificationMessage?> GetByProviderMessageIdAsync(string providerMessageId, CancellationToken cancellationToken = default);
}
