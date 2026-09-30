using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Notification;

/// <summary>
/// A single push/WhatsApp notification queued for one user (BRD §14/§25). Content is denormalized at creation time
/// (no FK back to the alert/report/etc. that triggered it) — a notification must remain readable exactly as sent
/// even if the source record later changes. Delivery itself is behind <c>INotificationSender</c>; until a real
/// gateway is wired up, every send is logged rather than dispatched (data model + admin CRUD only, per scope).
/// </summary>
public sealed class NotificationMessage : AggregateRoot<Guid>, IAuditableEntity
{
    public const int TitleMaxLength = 150;
    public const int BodyMaxLength = 1000;

    private NotificationMessage(Guid id, Guid userId, NotificationChannel channel, string title, string body)
        : base(id)
    {
        UserId = userId;
        Channel = channel;
        Title = title;
        Body = body;
        Status = NotificationStatus.Pending;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private NotificationMessage()
    {
        Title = string.Empty;
        Body = string.Empty;
    }

    public Guid UserId { get; private set; }

    public NotificationChannel Channel { get; private set; }

    public string Title { get; private set; }

    public string Body { get; private set; }

    public NotificationStatus Status { get; private set; }

    public DateTimeOffset? SentAtUtc { get; private set; }

    public string? FailureReason { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<NotificationMessage> Create(Guid userId, NotificationChannel channel, string? title, string? body)
    {
        if (userId == Guid.Empty)
        {
            return Error.Validation("NotificationMessage.UserRequired", "User is required.");
        }

        if (string.IsNullOrWhiteSpace(title) || title.Trim().Length > TitleMaxLength)
        {
            return Error.Validation("NotificationMessage.InvalidTitle", $"Title is required and must be at most {TitleMaxLength} characters.");
        }

        if (string.IsNullOrWhiteSpace(body) || body.Trim().Length > BodyMaxLength)
        {
            return Error.Validation("NotificationMessage.InvalidBody", $"Body is required and must be at most {BodyMaxLength} characters.");
        }

        return new NotificationMessage(Guid.CreateVersion7(), userId, channel, title.Trim(), body.Trim());
    }

    public void MarkSent(DateTimeOffset sentAtUtc)
    {
        Status = NotificationStatus.Sent;
        SentAtUtc = sentAtUtc;
        FailureReason = null;
    }

    public void MarkFailed(string reason)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(reason);

        Status = NotificationStatus.Failed;
        FailureReason = reason.Length > 500 ? reason[..500] : reason;
    }
}
