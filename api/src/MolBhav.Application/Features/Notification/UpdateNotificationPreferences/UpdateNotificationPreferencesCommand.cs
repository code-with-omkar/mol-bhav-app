using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Notification.GetNotificationPreferences;

namespace MolBhav.Application.Features.Notification.UpdateNotificationPreferences;

/// <summary>Saves the signed-in user's notification delivery preferences. Creates the row if it does not exist yet.</summary>
public sealed record UpdateNotificationPreferencesCommand(
    bool PushEnabled,
    bool AlertPushEnabled,
    bool PriceUpdatePushEnabled,
    bool WhatsAppEnabled,
    bool AlertWhatsAppEnabled) : ICommand<NotificationPreferencesResponse>;
