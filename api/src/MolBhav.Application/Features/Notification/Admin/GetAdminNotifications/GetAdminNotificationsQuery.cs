using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Notification.Models;
using MolBhav.Domain.Notification;

namespace MolBhav.Application.Features.Notification.Admin.GetAdminNotifications;

public sealed record GetAdminNotificationsQuery(
    Guid? UserId,
    NotificationChannel? Channel,
    NotificationStatus? Status,
    int Page,
    int PageSize) : IQuery<PagedResult<AdminNotificationResponse>>;
