using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Support.Events;

namespace MolBhav.Domain.Support;

/// <summary>
/// A help request raised from the app's Help &amp; Support screen, plus the conversation it carries. A ticket never
/// exists without its opening message, so <see cref="Create"/> writes both at once.
/// </summary>
/// <remarks>
/// Status is the admin's to set (<see cref="ChangeStatus"/> is reachable only from the admin endpoint), with two
/// exceptions the aggregate owns because they follow from the conversation itself: support answering an
/// <see cref="SupportTicketStatus.Open"/> ticket moves it to <see cref="SupportTicketStatus.InProgress"/>, and the
/// user replying to a <see cref="SupportTicketStatus.Resolved"/> one reopens it. <see cref="SupportTicketStatus.Closed"/>
/// is terminal: nothing may be added and no status may be set afterwards, so a closed ticket is a settled record.
/// <see cref="LastActivityAtUtc"/> is maintained by the aggregate rather than read off the audit columns — adding a
/// message does not modify any ticket column, so <c>UpdatedAtUtc</c> would not move and both list screens sort on
/// last activity.
/// </remarks>
public sealed class SupportTicket : AggregateRoot<Guid>, IAuditableEntity
{
    public const int SubjectMinLength = 5;
    public const int SubjectMaxLength = 120;

    private readonly List<SupportTicketMessage> _messages = [];

    private SupportTicket(
        Guid id,
        Guid userId,
        SupportTicketCategory category,
        string subject,
        DateTimeOffset openedAtUtc)
        : base(id)
    {
        UserId = userId;
        Category = category;
        Subject = subject;
        Status = SupportTicketStatus.Open;
        LastActivityAtUtc = openedAtUtc;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private SupportTicket()
    {
        Subject = string.Empty;
    }

    public Guid UserId { get; private set; }

    public SupportTicketCategory Category { get; private set; }

    public string Subject { get; private set; }

    public SupportTicketStatus Status { get; private set; }

    /// <summary>Newest message or status change; both ticket lists are ordered by it.</summary>
    public DateTimeOffset LastActivityAtUtc { get; private set; }

    public IReadOnlyCollection<SupportTicketMessage> Messages => _messages.AsReadOnly();

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    /// <summary>A ticket and the message that opened it, in one step — there is no such thing as an empty ticket.</summary>
    public static Result<SupportTicket> Create(
        Guid userId,
        SupportTicketCategory category,
        string? subject,
        string? body,
        DateTimeOffset openedAtUtc)
    {
        if (userId == Guid.Empty)
        {
            return Error.Validation("SupportTicket.UserRequired", "User is required.");
        }

        var trimmedSubject = subject?.Trim() ?? string.Empty;
        if (trimmedSubject.Length is < SubjectMinLength or > SubjectMaxLength)
        {
            return Error.Validation(
                "SupportTicket.InvalidSubject",
                $"Subject must be between {SubjectMinLength} and {SubjectMaxLength} characters.");
        }

        var bodyCheck = ValidateBody(body);
        if (bodyCheck.IsFailure)
        {
            return Result.Failure<SupportTicket>(bodyCheck.Error);
        }

        var ticket = new SupportTicket(Guid.CreateVersion7(), userId, category, trimmedSubject, openedAtUtc);
        ticket._messages.Add(new SupportTicketMessage(
            Guid.CreateVersion7(), SupportMessageAuthorKind.User, userId, body!.Trim(), openedAtUtc));

        return ticket;
    }

    /// <summary>The owner's reply. Reopens the ticket when it had been resolved; refused once closed.</summary>
    public Result AddUserMessage(string? body, DateTimeOffset sentAtUtc)
    {
        if (Status == SupportTicketStatus.Closed)
        {
            return Error.Validation("SupportTicket.Closed", "This ticket is closed. Please raise a new one.");
        }

        var bodyCheck = ValidateBody(body);
        if (bodyCheck.IsFailure)
        {
            return bodyCheck;
        }

        _messages.Add(new SupportTicketMessage(
            Guid.CreateVersion7(), SupportMessageAuthorKind.User, UserId, body!.Trim(), sentAtUtc));

        if (Status == SupportTicketStatus.Resolved)
        {
            Status = SupportTicketStatus.Open;
        }

        LastActivityAtUtc = sentAtUtc;
        return Result.Success();
    }

    /// <summary>
    /// Support's reply. Picks up an <see cref="SupportTicketStatus.Open"/> ticket into
    /// <see cref="SupportTicketStatus.InProgress"/> and raises <see cref="SupportTicketRepliedDomainEvent"/> so the
    /// owner is notified.
    /// </summary>
    public Result AddAdminMessage(Guid adminUserId, string? body, DateTimeOffset sentAtUtc)
    {
        if (adminUserId == Guid.Empty)
        {
            return Error.Validation("SupportTicket.AuthorRequired", "The replying admin is required.");
        }

        if (Status == SupportTicketStatus.Closed)
        {
            return Error.Validation("SupportTicket.Closed", "This ticket is closed and cannot be replied to.");
        }

        var bodyCheck = ValidateBody(body);
        if (bodyCheck.IsFailure)
        {
            return bodyCheck;
        }

        var message = new SupportTicketMessage(
            Guid.CreateVersion7(), SupportMessageAuthorKind.Admin, adminUserId, body!.Trim(), sentAtUtc);
        _messages.Add(message);

        if (Status == SupportTicketStatus.Open)
        {
            Status = SupportTicketStatus.InProgress;
        }

        LastActivityAtUtc = sentAtUtc;

        RaiseDomainEvent(new SupportTicketRepliedDomainEvent(Id, UserId, message.Id, Category, Subject, Status));
        return Result.Success();
    }

    /// <summary>Admin-only (see the type's remarks). Refused once closed — that state is terminal.</summary>
    public Result ChangeStatus(SupportTicketStatus status, DateTimeOffset changedAtUtc)
    {
        if (Status == SupportTicketStatus.Closed)
        {
            return Error.Validation("SupportTicket.Closed", "A closed ticket cannot change status.");
        }

        if (!Enum.IsDefined(status))
        {
            return Error.Validation("SupportTicket.InvalidStatus", "Unknown ticket status.");
        }

        if (status == Status)
        {
            return Result.Success();
        }

        Status = status;
        LastActivityAtUtc = changedAtUtc;
        return Result.Success();
    }

    private static Result ValidateBody(string? body)
    {
        var trimmed = body?.Trim() ?? string.Empty;
        return trimmed.Length is < SupportTicketMessage.BodyMinLength or > SupportTicketMessage.BodyMaxLength
            ? Error.Validation(
                "SupportTicket.InvalidMessage",
                $"Message must be between {SupportTicketMessage.BodyMinLength} and {SupportTicketMessage.BodyMaxLength} characters.")
            : Result.Success();
    }
}
