namespace MolBhav.Domain.Notification;

public enum NotificationStatus
{
    Pending = 0,
    Sent = 1,
    Failed = 2,

    /// <summary>The gateway confirmed the message reached the recipient (WhatsApp delivered/read receipt).</summary>
    Delivered = 3,
}
