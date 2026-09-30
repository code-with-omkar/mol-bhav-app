namespace MolBhav.Api.Contracts.Notification;

public sealed record UpdateNotificationPreferencesRequest(
    bool PushEnabled,
    bool AlertPushEnabled,
    bool PriceUpdatePushEnabled,
    bool WhatsAppEnabled,
    bool AlertWhatsAppEnabled);
