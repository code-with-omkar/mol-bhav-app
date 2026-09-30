using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Notification;

namespace MolBhav.Application.Abstractions.Notifications;

public interface INotificationRepository : IRepository<NotificationMessage, Guid>
{
}
