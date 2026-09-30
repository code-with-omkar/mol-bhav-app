using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Events;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Notification;
using MolBhav.Domain.Support.Events;

namespace MolBhav.Application.Features.Notification.SendSupportReplyNotification;

/// <summary>
/// Reacts to support answering a ticket by queuing a push notification for its owner — the same shape as
/// <c>AlertNotificationHandler</c>. Runs outside <c>UnitOfWorkBehavior</c> (dispatched from the outbox, not through
/// MediatR), so it commits its own unit of work.
/// </summary>
/// <remarks>
/// Unlike the alert and welcome handlers, the copy here comes from the LocalizedTexts store
/// (<c>support.reply.title</c> / <c>support.reply.body</c>) in the user's own preferred language — a background
/// handler has no request language to fall back on. The English seed is used if a key is missing, so a notification
/// is never dropped over copy.
/// </remarks>
internal sealed class SupportReplyNotificationHandler(
    INotificationRepository notifications,
    INotificationSender sender,
    ILocalizationReadService localization,
    IUserRepository users,
    IUnitOfWork unitOfWork,
    TimeProvider timeProvider) : IDomainEventHandler<SupportTicketRepliedDomainEvent>
{
    public const string TitleKey = "support.reply.title";
    public const string BodyKey = "support.reply.body";

    private const string FallbackTitle = "Support replied";
    private const string FallbackBody = "Our team replied to your ticket. Tap to read the answer.";

    public async Task HandleAsync(SupportTicketRepliedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(domainEvent);

        var user = await users.GetByIdAsync(domainEvent.UserId, cancellationToken);
        var language = user?.PreferredLanguage.Value ?? "en";
        var texts = await localization.GetTextsAsync(language, "support.reply.", cancellationToken);

        var title = texts.TryGetValue(TitleKey, out var localizedTitle) ? localizedTitle : FallbackTitle;
        var body = texts.TryGetValue(BodyKey, out var localizedBody) ? localizedBody : FallbackBody;

        // The subject is the user's own words, so it is appended rather than translated.
        var notification = NotificationMessage.Create(
            domainEvent.UserId,
            NotificationChannel.Push,
            title,
            $"{body} — {domainEvent.Subject}");

        if (notification.IsFailure)
        {
            return;
        }

        await DispatchAsync.SendAndMarkAsync(notification.Value, sender, timeProvider, cancellationToken);

        notifications.Add(notification.Value);
        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
