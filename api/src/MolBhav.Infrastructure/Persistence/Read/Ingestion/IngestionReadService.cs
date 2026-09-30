using Dapper;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Ingestion;
using MolBhav.Infrastructure.Persistence.Configurations.Ingestion;
using MolBhav.Infrastructure.Persistence.Configurations.Pricing;

namespace MolBhav.Infrastructure.Persistence.Read.Ingestion;

internal sealed class IngestionReadService(IDbConnectionFactory connectionFactory) : IIngestionReadService
{
    private const string Jobs = Schemas.Ingestion + "." + DataIngestionJobConfiguration.TableName;
    private const string Errors = Schemas.Ingestion + "." + DataIngestionErrorConfiguration.TableName;
    private const string Sources = Schemas.Pricing + "." + PriceSourceConfiguration.TableName;

    private const string JobsFrom = $"""
        FROM {Jobs} j
        JOIN {Sources} s ON s.id = j.price_source_id
        """;

    private const string JobsWhere = """
        WHERE (@PriceSourceId::uuid IS NULL OR j.price_source_id = @PriceSourceId::uuid)
          AND (@Status::text IS NULL OR j.status = @Status::text)
        """;

    private static readonly string AdminJobsSql = $"""
        SELECT count(*)
        {JobsFrom}
        {JobsWhere};

        SELECT j.id, j.price_source_id, s.code AS price_source_code, j.trigger_type, j.triggered_by_user_id, j.status,
               j.records_fetched, j.records_persisted, j.records_failed, j.failure_reason, j.started_at_utc, j.completed_at_utc
        {JobsFrom}
        {JobsWhere}
        ORDER BY j.started_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    private static readonly string AdminJobSql = $"""
        SELECT j.id, j.price_source_id, s.code AS price_source_code, j.trigger_type, j.triggered_by_user_id, j.status,
               j.records_fetched, j.records_persisted, j.records_failed, j.failure_reason, j.started_at_utc, j.completed_at_utc
        {JobsFrom}
        WHERE j.id = @JobId;
        """;

    private static readonly string AdminJobErrorsSql = $"""
        SELECT count(*) FROM {Errors} WHERE job_id = @JobId;

        SELECT id, job_id, raw_payload, error_message, occurred_at_utc
        FROM {Errors}
        WHERE job_id = @JobId
        ORDER BY occurred_at_utc
        LIMIT @Limit OFFSET @Offset;
        """;

    public async Task<PagedResult<AdminIngestionJobResponse>> GetAdminJobsAsync(AdminIngestionJobFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("PriceSourceId", filter.PriceSourceId);
        args.Add("Status", filter.Status?.ToString());
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminJobsSql, args, cancellationToken));

        var totalCount = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<JobRow>();

        return new PagedResult<AdminIngestionJobResponse>(rows.Select(ToResponse).ToArray(), filter.Page.Page, filter.Page.PageSize, totalCount);
    }

    public async Task<AdminIngestionJobResponse?> GetAdminJobAsync(Guid jobId, CancellationToken cancellationToken = default)
    {
        var args = new { JobId = jobId };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var row = await connection.QuerySingleOrDefaultAsync<JobRow>(Command(AdminJobSql, args, cancellationToken));

        return row is null ? null : ToResponse(row);
    }

    public async Task<PagedResult<AdminIngestionErrorResponse>> GetAdminJobErrorsAsync(Guid jobId, PageRequest page, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(page);

        var args = new { JobId = jobId, Limit = page.PageSize, Offset = page.Offset };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminJobErrorsSql, args, cancellationToken));

        var totalCount = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<ErrorRow>();

        return new PagedResult<AdminIngestionErrorResponse>(
            rows.Select(r => new AdminIngestionErrorResponse(r.Id, r.JobId, r.RawPayload, r.ErrorMessage, r.OccurredAtUtc)).ToArray(),
            page.Page, page.PageSize, totalCount);
    }

    private static AdminIngestionJobResponse ToResponse(JobRow r) => new(
        r.Id,
        r.PriceSourceId,
        r.PriceSourceCode,
        Enum.Parse<IngestionTriggerType>(r.TriggerType),
        r.TriggeredByUserId,
        Enum.Parse<IngestionJobStatus>(r.Status),
        r.RecordsFetched,
        r.RecordsPersisted,
        r.RecordsFailed,
        r.FailureReason,
        r.StartedAtUtc,
        r.CompletedAtUtc);

    private static CommandDefinition Command(string sql, object? args, CancellationToken cancellationToken) =>
        new(sql, args, cancellationToken: cancellationToken);

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class JobRow
    {
        public Guid Id { get; init; }

        public Guid PriceSourceId { get; init; }

        public string PriceSourceCode { get; init; } = string.Empty;

        public string TriggerType { get; init; } = string.Empty;

        public Guid? TriggeredByUserId { get; init; }

        public string Status { get; init; } = string.Empty;

        public int RecordsFetched { get; init; }

        public int RecordsPersisted { get; init; }

        public int RecordsFailed { get; init; }

        public string? FailureReason { get; init; }

        public DateTimeOffset StartedAtUtc { get; init; }

        public DateTimeOffset? CompletedAtUtc { get; init; }
    }

    private sealed class ErrorRow
    {
        public Guid Id { get; init; }

        public Guid JobId { get; init; }

        public string RawPayload { get; init; } = string.Empty;

        public string ErrorMessage { get; init; } = string.Empty;

        public DateTimeOffset OccurredAtUtc { get; init; }
    }
#pragma warning restore CA1812
}
