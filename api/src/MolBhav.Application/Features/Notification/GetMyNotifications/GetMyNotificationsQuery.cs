using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Notification.Models;

namespace MolBhav.Application.Features.Notification.GetMyNotifications;

public sealed record GetMyNotificationsQuery(int Page, int PageSize) : IQuery<PagedResult<NotificationResponse>>;
