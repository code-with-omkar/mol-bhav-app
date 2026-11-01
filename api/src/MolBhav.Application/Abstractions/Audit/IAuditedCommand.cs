namespace MolBhav.Application.Abstractions.Audit;

/// <summary>
/// Marks a command as an admin action to record in the audit log. When it succeeds for a signed-in user, an entry is
/// saved in the same transaction. Commands run by background jobs (no signed-in user) are not recorded. Implement it
/// explicitly so the members do not show up as command properties.
/// </summary>
public interface IAuditedCommand
{
    /// <summary>A stable code, <c>Area.Verb</c>, e.g. <c>User.Suspend</c>.</summary>
    string AuditAction { get; }

    /// <summary>The record acted on (an id or a name); null when there is none.</summary>
    string? AuditTarget { get; }

    /// <summary>A short plain-English description. Never put personal data, tokens or message text in it.</summary>
    string AuditSummary { get; }
}
