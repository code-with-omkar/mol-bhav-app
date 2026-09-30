using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Support;

/// <summary>
/// One turn in a <see cref="SupportTicket"/>'s conversation. Part of the ticket aggregate — created only through
/// the ticket and never loaded or saved on its own — and immutable once written: a support thread is a record of
/// what was actually said.
/// </summary>
public sealed class SupportTicketMessage : Entity<Guid>
{
    public const int BodyMinLength = 1;
    public const int BodyMaxLength = 2000;

    internal SupportTicketMessage(
        Guid id,
        SupportMessageAuthorKind authorKind,
        Guid authorUserId,
        string body,
        DateTimeOffset createdAtUtc)
        : base(id)
    {
        AuthorKind = authorKind;
        AuthorUserId = authorUserId;
        Body = body;
        CreatedAtUtc = createdAtUtc;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private SupportTicketMessage()
    {
        Body = string.Empty;
    }

    public SupportMessageAuthorKind AuthorKind { get; private set; }

    /// <summary>The ticket owner for a user message, the responding admin for an admin one.</summary>
    public Guid AuthorUserId { get; private set; }

    public string Body { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }
}
