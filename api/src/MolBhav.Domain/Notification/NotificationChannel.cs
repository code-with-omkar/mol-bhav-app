namespace MolBhav.Domain.Notification;

/// <summary>Delivery channel for a <see cref="NotificationMessage"/> (BRD §14/§25 — WhatsApp/push alerts).</summary>
public enum NotificationChannel
{
    Push = 0,
    WhatsApp = 1,
}
