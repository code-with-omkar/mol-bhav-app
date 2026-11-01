using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Audit;

/// <summary>
/// One thing an admin changed: who, what, which record and when. Append-only: entries are never edited or deleted, and
/// are written in the same transaction as the change they describe, so a change and its entry are saved together or not
/// at all. Texts are cut to fit rather than refused — recording must never be the reason an action fails.
/// </summary>
public sealed class AuditEntry : AggregateRoot<Guid>, IAuditableEntity
{
    public const int ActionMaxLength = 64;
    public const int TargetMaxLength = 200;
    public const int SummaryMaxLength = 300;

    private AuditEntry(Guid id, Guid actorUserId, string action, string? target, string summary, DateTimeOffset occurredAtUtc)
        : base(id)
    {
        ActorUserId = actorUserId;
        Action = action;
        Target = target;
        Summary = summary;
        OccurredAtUtc = occurredAtUtc;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private AuditEntry()
    {
        Action = string.Empty;
        Summary = string.Empty;
    }

    /// <summary>The admin who did it.</summary>
    public Guid ActorUserId { get; private set; }

    /// <summary>A stable code such as <c>User.Suspend</c> or <c>Feature.Set</c>.</summary>
    public string Action { get; private set; }

    /// <summary>The record it was done to (a user id, a feature name, a state); null when there is none.</summary>
    public string? Target { get; private set; }

    /// <summary>A short plain-English description, with no personal data or secrets.</summary>
    public string Summary { get; private set; }

    public DateTimeOffset OccurredAtUtc { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static AuditEntry Create(Guid actorUserId, string? action, string? target, string? summary, DateTimeOffset occurredAtUtc) =>
        new(
            Guid.CreateVersion7(),
            actorUserId,
            Cut(action, ActionMaxLength) ?? "Unknown",
            Cut(target, TargetMaxLength),
            Cut(summary, SummaryMaxLength) ?? string.Empty,
            occurredAtUtc);

    private static string? Cut(string? value, int max)
    {
        var text = value?.Trim();
        if (string.IsNullOrEmpty(text))
        {
            return null;
        }

        return text.Length <= max ? text : text[..max];
    }
}
