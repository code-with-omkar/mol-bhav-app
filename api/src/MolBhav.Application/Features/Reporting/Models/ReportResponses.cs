using MolBhav.Domain.Reporting;

namespace MolBhav.Application.Features.Reporting.Models;

public sealed record ReportResponse(
    Guid Id,
    ReportType ReportType,
    ReportFormat Format,
    ReportStatus Status,
    string? DownloadUrl,
    string? FailureReason,
    DateTimeOffset RequestedAtUtc,
    DateTimeOffset? CompletedAtUtc,
    DateTimeOffset? LastDownloadedAtUtc);

public sealed record AdminReportResponse(
    Guid Id,
    Guid UserId,
    ReportType ReportType,
    ReportFormat Format,
    ReportStatus Status,
    string? FailureReason,
    DateTimeOffset RequestedAtUtc,
    DateTimeOffset? CompletedAtUtc);
