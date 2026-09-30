using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Notification.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Notification.GetMyNotifications;

internal sealed class GetMyNotificationsQueryHandler(INotificationReadService readService, ICurrentUser currentUser)
    : IQueryHandler<GetMyNotificationsQuery, PagedResult<NotificationResponse>>
{
    public async Task<Result<PagedResult<NotificationResponse>>> Handle(GetMyNotificationsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetMyNotificationsAsync(
            currentUser.GetRequiredUserId(), new PageRequest(request.Page, request.PageSize), cancellationToken));
}
