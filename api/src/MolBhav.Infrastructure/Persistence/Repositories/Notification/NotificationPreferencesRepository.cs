using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Notification;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Notification;

internal sealed class NotificationPreferencesRepository(MolBhavDbContext dbContext)
    : Repository<NotificationPreferences, Guid>(dbContext), INotificationPreferencesRepository
{
    public Task<NotificationPreferences?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default) =>
        Set.FindAsync([userId], cancellationToken).AsTask();
}
