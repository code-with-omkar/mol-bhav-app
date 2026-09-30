namespace MolBhav.Application.Features.Notification.GetNotificationPreferences;

public sealed record NotificationPreferencesResponse(
    bool PushEnabled,
    bool AlertPushEnabled,
    bool PriceUpdatePushEnabled,
    bool WhatsAppEnabled,
    bool AlertWhatsAppEnabled);
