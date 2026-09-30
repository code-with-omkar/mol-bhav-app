using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Notification;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Notification;

internal sealed class NotificationRepository(MolBhavDbContext dbContext) : Repository<NotificationMessage, Guid>(dbContext), INotificationRepository
{
}
