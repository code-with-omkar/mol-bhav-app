using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Reporting.Events;

namespace MolBhav.Domain.Reporting;

/// <summary>
/// A user-requested export (BRD §25: reports/exports). Generation itself is async and behind
/// <c>IReportGenerator</c>; the rendered file is stored separately and served by the download endpoint once
/// <see cref="ReportStatus.Ready"/>.
/// </summary>
public sealed class Report : AggregateRoot<Guid>, IAuditableEntity
{
    public const int ParametersJsonMaxLength = 4000;
    public const int FailureReasonMaxLength = 500;

    private Report(Guid id, Guid userId, ReportType reportType, ReportFormat format, string parametersJson, DateTimeOffset requestedAtUtc)
        : base(id)
    {
        UserId = userId;
        ReportType = reportType;
        Format = format;
        ParametersJson = parametersJson;
        Status = ReportStatus.Pending;
        RequestedAtUtc = requestedAtUtc;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private Report()
    {
        ParametersJson = string.Empty;
    }

    public Guid UserId { get; private set; }

    public ReportType ReportType { get; private set; }

    public ReportFormat Format { get; private set; }

    /// <summary>Report-type-specific filters (date range, product id, etc.) as a JSON object; the generator interprets it per <see cref="ReportType"/>.</summary>
    public string ParametersJson { get; private set; }

    public ReportStatus Status { get; private set; }

    public string? DownloadUrl { get; private set; }

    public string? FailureReason { get; private set; }

    public DateTimeOffset RequestedAtUtc { get; private set; }

    public DateTimeOffset? CompletedAtUtc { get; private set; }

    /// <summary>When the owner last fetched the rendered file; null until they download it once.</summary>
    public DateTimeOffset? LastDownloadedAtUtc { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<Report> Create(Guid userId, ReportType reportType, ReportFormat format, string? parametersJson, DateTimeOffset requestedAtUtc)
    {
        if (userId == Guid.Empty)
        {
            return Error.Validation("Report.UserRequired", "User is required.");
        }

        var json = parametersJson ?? "{}";
        if (json.Length > ParametersJsonMaxLength)
        {
            return Error.Validation("Report.ParametersTooLarge", $"Parameters must be at most {ParametersJsonMaxLength} characters once serialized.");
        }

        var report = new Report(Guid.CreateVersion7(), userId, reportType, format, json, requestedAtUtc);
        report.RaiseDomainEvent(new ReportRequestedDomainEvent(report.Id, userId, reportType, format, json));
        return report;
    }

    public void MarkReady(string downloadUrl, DateTimeOffset completedAtUtc)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(downloadUrl);

        Status = ReportStatus.Ready;
        DownloadUrl = downloadUrl;
        FailureReason = null;
        CompletedAtUtc = completedAtUtc;
    }

    public void MarkFailed(string reason, DateTimeOffset completedAtUtc)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(reason);

        Status = ReportStatus.Failed;
        FailureReason = reason.Length > FailureReasonMaxLength ? reason[..FailureReasonMaxLength] : reason;
        CompletedAtUtc = completedAtUtc;
    }

    /// <summary>Stamps the latest successful owner download; each one overwrites the last.</summary>
    public void MarkDownloaded(DateTimeOffset downloadedAtUtc) => LastDownloadedAtUtc = downloadedAtUtc;
}
