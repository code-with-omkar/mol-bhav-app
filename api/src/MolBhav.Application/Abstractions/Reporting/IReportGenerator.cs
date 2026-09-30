using MolBhav.Domain.Reporting;

namespace MolBhav.Application.Abstractions.Reporting;

/// <summary>
/// Renders a requested report, stores the file, and returns where to download it. Report type/format pairs without a
/// renderer (see <see cref="ReportParameters.IsSupported"/>) return a failed outcome with a specific reason.
/// </summary>
public interface IReportGenerator
{
    Task<ReportGenerationOutcome> GenerateAsync(ReportGenerationRequest request, CancellationToken cancellationToken = default);
}

public sealed record ReportGenerationRequest(Guid ReportId, Guid UserId, ReportType ReportType, ReportFormat Format, string ParametersJson);

public sealed record ReportGenerationOutcome
{
    private ReportGenerationOutcome(bool isSuccess, string? downloadUrl, string? failureReason)
    {
        IsSuccess = isSuccess;
        DownloadUrl = downloadUrl;
        FailureReason = failureReason;
    }

    public bool IsSuccess { get; }

    public string? DownloadUrl { get; }

    public string? FailureReason { get; }

    public static ReportGenerationOutcome Success(string downloadUrl) => new(true, downloadUrl, null);

    public static ReportGenerationOutcome Failed(string reason) => new(false, null, reason);
}
