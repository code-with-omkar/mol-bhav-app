using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Notification;

/// <summary>
/// Per-user notification delivery preferences. <c>Id == UserId</c> — one row per user, created on first save with
/// all channels on by default. The sub-toggles (alert / price-update) only take effect when the master toggle is on.
/// </summary>
public sealed class NotificationPreferences : AggregateRoot<Guid>, IAuditableEntity
{
    private NotificationPreferences(Guid userId)
        : base(userId)
    {
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private NotificationPreferences()
    {
    }

    /// <summary>Master switch: when false, no push notification is ever sent.</summary>
    public bool PushEnabled { get; private set; } = true;

    /// <summary>Alert-triggered push (e.g. price spike). Only effective when <see cref="PushEnabled"/> is true.</summary>
    public bool AlertPushEnabled { get; private set; } = true;

    /// <summary>Scheduled price-update push. Only effective when <see cref="PushEnabled"/> is true.</summary>
    public bool PriceUpdatePushEnabled { get; private set; }

    /// <summary>Master switch: when false, no WhatsApp message is ever sent.</summary>
    public bool WhatsAppEnabled { get; private set; }

    /// <summary>Alert-triggered WhatsApp (e.g. price spike). Only effective when <see cref="WhatsAppEnabled"/> is true.</summary>
    public bool AlertWhatsAppEnabled { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static NotificationPreferences CreateDefault(Guid userId) =>
        new(userId)
        {
            PushEnabled = true,
            AlertPushEnabled = true,
            PriceUpdatePushEnabled = false,
            WhatsAppEnabled = false,
            AlertWhatsAppEnabled = false,
        };

    public void Update(bool push, bool alertPush, bool priceUpdatePush, bool whatsApp, bool alertWhatsApp)
    {
        PushEnabled = push;
        AlertPushEnabled = alertPush;
        PriceUpdatePushEnabled = priceUpdatePush;
        WhatsAppEnabled = whatsApp;
        AlertWhatsAppEnabled = alertWhatsApp;
    }
}
