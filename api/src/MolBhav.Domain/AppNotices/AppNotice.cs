using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.AppNotices;

/// <summary>How the app shows a notice: a note, a warning, or a full-screen "back soon" page.</summary>
public enum NoticeSeverity
{
    /// <summary>A neutral banner (new feature, planned downtime tonight).</summary>
    Info = 0,

    /// <summary>An attention-grabbing banner (a problem users may notice).</summary>
    Warning = 1,

    /// <summary>Blocks the app with a "back soon" page; used while the service is down for maintenance.</summary>
    Maintenance = 2,
}

/// <summary>
/// The one message an admin can show every user (planned downtime, a known problem, maintenance). A single row for the
/// whole app, edited in place; turning it off keeps the text so it can be switched back on.
/// </summary>
public sealed class AppNotice : AggregateRoot<Guid>, IAuditableEntity
{
    public const int MessageMaxLength = 280;

    private AppNotice(Guid id, bool isActive, NoticeSeverity severity, string message)
        : base(id)
    {
        IsActive = isActive;
        Severity = severity;
        Message = message;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private AppNotice()
    {
        Message = string.Empty;
    }

    /// <summary>Whether users see it.</summary>
    public bool IsActive { get; private set; }

    public NoticeSeverity Severity { get; private set; }

    public string Message { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<AppNotice> Create(bool isActive, NoticeSeverity severity, string? message)
    {
        var validated = Validate(isActive, severity, message);
        if (validated.IsFailure)
        {
            return validated.Error;
        }

        return new AppNotice(Guid.CreateVersion7(), isActive, severity, validated.Value);
    }

    public Result Update(bool isActive, NoticeSeverity severity, string? message)
    {
        var validated = Validate(isActive, severity, message);
        if (validated.IsFailure)
        {
            return validated.Error;
        }

        IsActive = isActive;
        Severity = severity;
        Message = validated.Value;
        return Result.Success();
    }

    /// <summary>The trimmed message; one is required only while the notice is on (an off notice may keep old text or none).</summary>
    private static Result<string> Validate(bool isActive, NoticeSeverity severity, string? message)
    {
        if (!Enum.IsDefined(severity))
        {
            return Error.Validation("AppNotice.SeverityInvalid", "Unknown notice type.");
        }

        var text = message?.Trim() ?? string.Empty;
        if (isActive && text.Length == 0)
        {
            return Error.Validation("AppNotice.MessageRequired", "Write the message users should see.");
        }

        return text.Length > MessageMaxLength
            ? Error.Validation("AppNotice.MessageTooLong", $"The message can be at most {MessageMaxLength} characters.")
            : text;
    }
}
