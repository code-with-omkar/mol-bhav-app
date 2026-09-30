using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Notification.Models;
using MolBhav.Domain.Notification;

namespace MolBhav.Application.Abstractions.Notifications;

/// <summary>Dapper-backed reads for the signed-in user's notification inbox and the admin monitoring list.</summary>
public interface INotificationReadService
{
    Task<PagedResult<NotificationResponse>> GetMyNotificationsAsync(Guid userId, PageRequest page, CancellationToken cancellationToken = default);

    Task<PagedResult<AdminNotificationResponse>> GetAdminNotificationsAsync(AdminNotificationFilter filter, CancellationToken cancellationToken = default);
}

public sealed record AdminNotificationFilter(Guid? UserId, NotificationChannel? Channel, NotificationStatus? Status, PageRequest Page);
