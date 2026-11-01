using MolBhav.Domain.Notification;

namespace MolBhav.Application.Features.Notification;

/// <summary>The channels a user wants alerts on (price alerts and market opportunities share the same switches):
/// push unless "alerts by push" is off, WhatsApp only when both WhatsApp and "alerts on WhatsApp" are on. The channel
/// master switches are applied again by the sender.</summary>
internal static class AlertChannels
{
    public static IReadOnlyList<NotificationChannel> For(NotificationPreferences? prefs)
    {
        var channels = new List<NotificationChannel>(2);
        if (prefs?.AlertPushEnabled ?? true)
        {
            channels.Add(NotificationChannel.Push);
        }

        if (prefs is { WhatsAppEnabled: true, AlertWhatsAppEnabled: true })
        {
            channels.Add(NotificationChannel.WhatsApp);
        }

        return channels;
    }
}
