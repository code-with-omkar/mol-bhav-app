namespace MolBhav.Infrastructure.Reporting;

/// <summary>
/// A rendered report's bytes, 1:1 with <c>reporting.reports</c>. Kept in its own table so listing reports never
/// reads file content. Stored in PostgreSQL (<c>bytea</c>) until volumes justify object storage.
/// </summary>
internal sealed class ReportFile
{
    public ReportFile(Guid reportId, string fileName, string contentType, byte[] content, DateTimeOffset createdAtUtc)
    {
        ReportId = reportId;
        FileName = fileName;
        ContentType = contentType;
        Content = content;
        SizeBytes = content.LongLength;
        CreatedAtUtc = createdAtUtc;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private ReportFile()
    {
        FileName = string.Empty;
        ContentType = string.Empty;
        Content = [];
    }

    public Guid ReportId { get; private set; }

    public string FileName { get; private set; }

    public string ContentType { get; private set; }

    public long SizeBytes { get; private set; }

    public byte[] Content { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public void Replace(string fileName, string contentType, byte[] content, DateTimeOffset createdAtUtc)
    {
        FileName = fileName;
        ContentType = contentType;
        Content = content;
        SizeBytes = content.LongLength;
        CreatedAtUtc = createdAtUtc;
    }
}
