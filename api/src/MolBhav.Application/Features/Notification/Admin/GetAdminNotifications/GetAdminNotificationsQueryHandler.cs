using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Notification.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Notification.Admin.GetAdminNotifications;

internal sealed class GetAdminNotificationsQueryHandler(INotificationReadService readService)
    : IQueryHandler<GetAdminNotificationsQuery, PagedResult<AdminNotificationResponse>>
{
    public async Task<Result<PagedResult<AdminNotificationResponse>>> Handle(GetAdminNotificationsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminNotificationsAsync(
            new AdminNotificationFilter(request.UserId, request.Channel, request.Status, new PageRequest(request.Page, request.PageSize)),
            cancellationToken));
}
