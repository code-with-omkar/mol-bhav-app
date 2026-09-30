using Dapper;
using MolBhav.Application.Abstractions.Reporting;
using MolBhav.Infrastructure.Persistence.Configurations.Reporting;

namespace MolBhav.Infrastructure.Persistence.Read.Reporting;

internal sealed class ReportFileStore(IDbConnectionFactory connectionFactory) : IReportFileStore
{
    private const string Sql = $"""
        SELECT f.file_name, f.content_type, f.content
        FROM {Schemas.Reporting}.{ReportFileConfiguration.TableName} f
        JOIN {Schemas.Reporting}.{ReportConfiguration.TableName} r ON r.id = f.report_id
        WHERE f.report_id = @ReportId AND r.user_id = @UserId;
        """;

    public async Task<ReportFileContent?> GetAsync(Guid reportId, Guid userId, CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var row = await connection.QuerySingleOrDefaultAsync<FileRow>(
            new CommandDefinition(Sql, new { ReportId = reportId, UserId = userId }, cancellationToken: cancellationToken));

        return row is null ? null : new ReportFileContent(row.FileName, row.ContentType, row.Content);
    }

    private sealed class FileRow
    {
        public string FileName { get; init; } = string.Empty;

        public string ContentType { get; init; } = string.Empty;

        public byte[] Content { get; init; } = [];
    }
}
