using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Application.Features.Notification.GetNotificationPreferences;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Notification;

namespace MolBhav.Application.Features.Notification.UpdateNotificationPreferences;

internal sealed class UpdateNotificationPreferencesCommandHandler(
    INotificationPreferencesRepository preferences,
    ICurrentUser currentUser)
    : ICommandHandler<UpdateNotificationPreferencesCommand, NotificationPreferencesResponse>
{
    public async Task<Result<NotificationPreferencesResponse>> Handle(
        UpdateNotificationPreferencesCommand request,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        var prefs = await preferences.GetByUserIdAsync(userId, cancellationToken);

        if (prefs is null)
        {
            prefs = NotificationPreferences.CreateDefault(userId);
            preferences.Add(prefs);
        }

        prefs.Update(
            request.PushEnabled,
            request.AlertPushEnabled,
            request.PriceUpdatePushEnabled,
            request.WhatsAppEnabled,
            request.AlertWhatsAppEnabled);

        return new NotificationPreferencesResponse(
            prefs.PushEnabled,
            prefs.AlertPushEnabled,
            prefs.PriceUpdatePushEnabled,
            prefs.WhatsAppEnabled,
            prefs.AlertWhatsAppEnabled);
    }
}
