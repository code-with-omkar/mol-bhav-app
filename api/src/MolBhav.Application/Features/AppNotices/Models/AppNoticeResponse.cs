using MolBhav.Domain.AppNotices;

namespace MolBhav.Application.Features.AppNotices.Models;

/// <summary>
/// The message shown to every user. <c>isActive</c> false means nothing to show; the admin app still gets the saved
/// <c>message</c> and <c>severity</c> so it can be edited or switched back on.
/// </summary>
public sealed record AppNoticeResponse(bool IsActive, NoticeSeverity Severity, string Message, DateTimeOffset? UpdatedAtUtc);

/// <param name="IsActive">Whether users see the notice.</param>
public sealed record SetAppNoticeRequest(bool IsActive, NoticeSeverity Severity, string? Message);
