using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Notification;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Notification;

internal sealed class NotificationRepository(MolBhavDbContext dbContext) : Repository<NotificationMessage, Guid>(dbContext), INotificationRepository
{
    public Task<NotificationMessage?> GetByProviderMessageIdAsync(string providerMessageId, CancellationToken cancellationToken = default) =>
        Set.FirstOrDefaultAsync(n => n.ProviderMessageId == providerMessageId, cancellationToken);
}
