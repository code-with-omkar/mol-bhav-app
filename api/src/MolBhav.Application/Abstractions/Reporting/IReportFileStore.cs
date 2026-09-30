namespace MolBhav.Application.Abstractions.Reporting;

/// <summary>Rendered report files. Reads are owner-scoped: another user's report id behaves as not found.</summary>
public interface IReportFileStore
{
    /// <summary>Null when the report doesn't exist, belongs to someone else, or has no file yet.</summary>
    Task<ReportFileContent?> GetAsync(Guid reportId, Guid userId, CancellationToken cancellationToken = default);
}

public sealed record ReportFileContent(string FileName, string ContentType, byte[] Content);
