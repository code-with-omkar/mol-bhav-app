using Dapper;
using MolBhav.Application.Abstractions.Reporting;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Reporting.Models;
using MolBhav.Domain.Reporting;
using MolBhav.Infrastructure.Persistence.Configurations.Reporting;

namespace MolBhav.Infrastructure.Persistence.Read.Reporting;

internal sealed class ReportReadService(IDbConnectionFactory connectionFactory) : IReportReadService
{
    private const string Reports = Schemas.Reporting + "." + ReportConfiguration.TableName;

    private const string MySql = $"""
        SELECT count(*) FROM {Reports} r WHERE r.user_id = @UserId;

        SELECT r.id, r.report_type, r.format, r.status, r.download_url, r.failure_reason, r.requested_at_utc,
               r.completed_at_utc, r.last_downloaded_at_utc
        FROM {Reports} r
        WHERE r.user_id = @UserId
        ORDER BY r.requested_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    private const string OneSql = $"""
        SELECT r.id, r.report_type, r.format, r.status, r.download_url, r.failure_reason, r.requested_at_utc,
               r.completed_at_utc, r.last_downloaded_at_utc
        FROM {Reports} r
        WHERE r.id = @ReportId AND r.user_id = @UserId;
        """;

    private const string AdminFrom = $"""
        FROM {Reports} r
        """;

    private const string AdminWhere = """
        WHERE (@UserId::uuid IS NULL OR r.user_id = @UserId::uuid)
          AND (@ReportType::text IS NULL OR r.report_type = @ReportType::text)
          AND (@Status::text IS NULL OR r.status = @Status::text)
        """;

    private static readonly string AdminSql = $"""
        SELECT count(*)
        {AdminFrom}
        {AdminWhere};

        SELECT r.id, r.user_id, r.report_type, r.format, r.status, r.failure_reason, r.requested_at_utc, r.completed_at_utc
        {AdminFrom}
        {AdminWhere}
        ORDER BY r.requested_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    public async Task<PagedResult<ReportResponse>> GetMyReportsAsync(Guid userId, PageRequest page, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(page);

        var args = new { UserId = userId, Limit = page.PageSize, Offset = page.Offset };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(MySql, args, cancellationToken));

        var totalCount = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<ReportRow>();

        return new PagedResult<ReportResponse>(rows.Select(ToResponse).ToArray(), page.Page, page.PageSize, totalCount);
    }

    public async Task<ReportResponse?> GetReportAsync(Guid reportId, Guid userId, CancellationToken cancellationToken = default)
    {
        var args = new { ReportId = reportId, UserId = userId };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var row = await connection.QuerySingleOrDefaultAsync<ReportRow>(Command(OneSql, args, cancellationToken));

        return row is null ? null : ToResponse(row);
    }

    public async Task<PagedResult<AdminReportResponse>> GetAdminReportsAsync(AdminReportFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("UserId", filter.UserId);
        args.Add("ReportType", filter.ReportType?.ToString());
        args.Add("Status", filter.Status?.ToString());
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminSql, args, cancellationToken));

        var totalCount = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<AdminReportRow>();

        return new PagedResult<AdminReportResponse>(
            rows.Select(r => new AdminReportResponse(
                r.Id, r.UserId, Enum.Parse<ReportType>(r.ReportType), Enum.Parse<ReportFormat>(r.Format),
                Enum.Parse<ReportStatus>(r.Status), r.FailureReason, r.RequestedAtUtc, r.CompletedAtUtc)).ToArray(),
            filter.Page.Page, filter.Page.PageSize, totalCount);
    }

    private static ReportResponse ToResponse(ReportRow r) => new(
        r.Id, Enum.Parse<ReportType>(r.ReportType), Enum.Parse<ReportFormat>(r.Format),
        Enum.Parse<ReportStatus>(r.Status), r.DownloadUrl, r.FailureReason, r.RequestedAtUtc, r.CompletedAtUtc, r.LastDownloadedAtUtc);

    private static CommandDefinition Command(string sql, object? args, CancellationToken cancellationToken) =>
        new(sql, args, cancellationToken: cancellationToken);

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class ReportRow
    {
        public Guid Id { get; init; }

        public string ReportType { get; init; } = string.Empty;

        public string Format { get; init; } = string.Empty;

        public string Status { get; init; } = string.Empty;

        public string? DownloadUrl { get; init; }

        public string? FailureReason { get; init; }

        public DateTimeOffset RequestedAtUtc { get; init; }

        public DateTimeOffset? CompletedAtUtc { get; init; }

        public DateTimeOffset? LastDownloadedAtUtc { get; init; }
    }

    private sealed class AdminReportRow
    {
        public Guid Id { get; init; }

        public Guid UserId { get; init; }

        public string ReportType { get; init; } = string.Empty;

        public string Format { get; init; } = string.Empty;

        public string Status { get; init; } = string.Empty;

        public string? FailureReason { get; init; }

        public DateTimeOffset RequestedAtUtc { get; init; }

        public DateTimeOffset? CompletedAtUtc { get; init; }
    }
#pragma warning restore CA1812
}
