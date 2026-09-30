using MolBhav.Domain.Notification;

namespace MolBhav.Application.Abstractions.Notifications;

public interface INotificationPreferencesRepository
{
    Task<NotificationPreferences?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);

    void Add(NotificationPreferences preferences);
}
