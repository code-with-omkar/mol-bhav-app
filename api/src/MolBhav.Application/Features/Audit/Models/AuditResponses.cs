namespace MolBhav.Application.Features.Audit.Models;

/// <summary>One recorded admin action.</summary>
/// <param name="Action">A stable code such as <c>User.Suspend</c>.</param>
/// <param name="Target">The record acted on (an id or a name); null when there is none.</param>
/// <param name="Summary">A short plain-English description.</param>
/// <param name="ActorUserId">The admin who did it.</param>
/// <param name="ActorName">Their display name, or their phone number when they have none; null if the account is gone.</param>
public sealed record AuditEntryResponse(
    Guid Id,
    DateTimeOffset OccurredAtUtc,
    string Action,
    string? Target,
    string Summary,
    Guid ActorUserId,
    string? ActorName);
