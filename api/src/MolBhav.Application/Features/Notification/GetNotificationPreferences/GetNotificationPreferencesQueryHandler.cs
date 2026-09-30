using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Notification.GetNotificationPreferences;

internal sealed class GetNotificationPreferencesQueryHandler(
    INotificationPreferencesRepository preferences,
    ICurrentUser currentUser)
    : IQueryHandler<GetNotificationPreferencesQuery, NotificationPreferencesResponse>
{
    public async Task<Result<NotificationPreferencesResponse>> Handle(
        GetNotificationPreferencesQuery request,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        var prefs = await preferences.GetByUserIdAsync(userId, cancellationToken);

        // Return defaults when the user has never saved preferences.
        return Result.Success(new NotificationPreferencesResponse(
            prefs?.PushEnabled ?? true,
            prefs?.AlertPushEnabled ?? true,
            prefs?.PriceUpdatePushEnabled ?? false,
            prefs?.WhatsAppEnabled ?? false,
            prefs?.AlertWhatsAppEnabled ?? false));
    }
}
