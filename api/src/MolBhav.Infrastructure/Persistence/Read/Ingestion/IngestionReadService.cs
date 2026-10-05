using Dapper;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Ingestion;
using MolBhav.Infrastructure.Persistence.Configurations.Catalog;
using MolBhav.Infrastructure.Persistence.Configurations.Ingestion;
using MolBhav.Infrastructure.Persistence.Configurations.Pricing;

namespace MolBhav.Infrastructure.Persistence.Read.Ingestion;

internal sealed class IngestionReadService(IDbConnectionFactory connectionFactory) : IIngestionReadService
{
    private const string Jobs = Schemas.Ingestion + "." + DataIngestionJobConfiguration.TableName;
    private const string Errors = Schemas.Ingestion + "." + DataIngestionErrorConfiguration.TableName;
    private const string Sources = Schemas.Pricing + "." + PriceSourceConfiguration.TableName;
    private const string Schedules = Schemas.Ingestion + "." + IngestionScheduleConfiguration.TableName;
    private const string Categories = Schemas.Catalog + "." + ProcurementCategoryConfiguration.TableName;
    private const string CategoryTranslations = Schemas.Catalog + "." + ProcurementCategoryConfiguration.TranslationsTableName;

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

        SELECT j.id, j.price_source_id, s.code AS price_source_code, j.trigger_type, j.triggered_by_user_id, j.status, j.as_of_date,
               j.records_fetched, j.records_persisted, j.records_unchanged, j.records_failed, j.failure_reason, j.started_at_utc, j.completed_at_utc
        {JobsFrom}
        {JobsWhere}
        ORDER BY j.started_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    private static readonly string AdminJobSql = $"""
        SELECT j.id, j.price_source_id, s.code AS price_source_code, j.trigger_type, j.triggered_by_user_id, j.status, j.as_of_date,
               j.records_fetched, j.records_persisted, j.records_unchanged, j.records_failed, j.failure_reason, j.started_at_utc, j.completed_at_utc
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

    // LATERAL picks each source's newest job via the (price_source_id, started_at_utc) index; the category name falls
    // back requested → default → English. Rows come grouped by category (display order) so the app can render sections.
    private static readonly string AdminSchedulesSql = $"""
        SELECT s.id AS price_source_id, s.code AS price_source_code, s.name AS price_source_name,
               s.is_active AS price_source_is_active,
               c.code AS category_code, COALESCE(cn.name, c.code) AS category_name, c.display_order AS category_display_order,
               sc.id AS schedule_id, sc.is_enabled, sc.frequency, to_char(sc.time_of_day, 'HH24:MI') AS time_of_day, sc.day_of_week, sc.interval_hours,
               sc.next_run_at_utc, sc.last_run_at_utc,
               lj.id AS last_job_id, lj.trigger_type AS last_job_trigger_type, lj.status AS last_job_status,
               lj.as_of_date AS last_job_as_of_date, lj.records_persisted AS last_job_records_persisted,
               lj.records_unchanged AS last_job_records_unchanged, lj.records_failed AS last_job_records_failed,
               lj.failure_reason AS last_job_failure_reason, lj.started_at_utc AS last_job_started_at_utc,
               lj.completed_at_utc AS last_job_completed_at_utc
        FROM {Sources} s
        JOIN {Categories} c ON c.id = s.category_id
        LEFT JOIN LATERAL (
            SELECT t.name
            FROM {CategoryTranslations} t
            WHERE t.category_id = c.id AND t.language_code IN (@Lang, @DefaultLang, 'en')
            ORDER BY CASE t.language_code WHEN @Lang THEN 0 WHEN @DefaultLang THEN 1 ELSE 2 END
            LIMIT 1
        ) cn ON TRUE
        LEFT JOIN {Schedules} sc ON sc.price_source_id = s.id
        LEFT JOIN LATERAL (
            SELECT j.id, j.trigger_type, j.status, j.as_of_date, j.records_persisted, j.records_unchanged, j.records_failed, j.failure_reason,
                   j.started_at_utc, j.completed_at_utc
            FROM {Jobs} j
            WHERE j.price_source_id = s.id
            ORDER BY j.started_at_utc DESC
            LIMIT 1
        ) lj ON TRUE
        WHERE (@CategoryCode::text IS NULL OR c.code = @CategoryCode::text)
        ORDER BY c.display_order, c.code, s.is_active DESC, s.name;
        """;

    public async Task<IReadOnlyList<AdminIngestionScheduleResponse>> GetAdminSchedulesAsync(
        AdminIngestionScheduleFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("CategoryCode", filter.CategoryCode);
        args.Add("Lang", filter.Language.Requested);
        args.Add("DefaultLang", filter.Language.Default);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<ScheduleRow>(Command(AdminSchedulesSql, args, cancellationToken));
        return rows.Select(ToScheduleResponse).ToArray();
    }

    private static AdminIngestionScheduleResponse ToScheduleResponse(ScheduleRow r) => new(
        r.PriceSourceId,
        r.PriceSourceCode,
        r.PriceSourceName,
        r.PriceSourceIsActive,
        r.CategoryCode,
        r.CategoryName,
        r.CategoryDisplayOrder,
        IsConfigured: r.ScheduleId is not null,
        IsEnabled: r.IsEnabled ?? false,
        Frequency: r.Frequency is null ? null : Enum.Parse<IngestionScheduleFrequency>(r.Frequency),
        r.TimeOfDay,
        DayOfWeek: r.DayOfWeek is null ? null : Enum.Parse<DayOfWeek>(r.DayOfWeek),
        r.IntervalHours,
        r.NextRunAtUtc,
        r.LastRunAtUtc,
        LastJob: r.LastJobId is not { } jobId
            ? null
            : new AdminIngestionLastJobResponse(
                jobId,
                Enum.Parse<IngestionTriggerType>(r.LastJobTriggerType!),
                Enum.Parse<IngestionJobStatus>(r.LastJobStatus!),
                r.LastJobAsOfDate,
                r.LastJobRecordsPersisted ?? 0,
                r.LastJobRecordsUnchanged ?? 0,
                r.LastJobRecordsFailed ?? 0,
                r.LastJobFailureReason,
                r.LastJobStartedAtUtc!.Value,
                r.LastJobCompletedAtUtc));

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
        r.AsOfDate,
        r.RecordsFetched,
        r.RecordsPersisted,
        r.RecordsUnchanged,
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

        public DateOnly? AsOfDate { get; init; }

        public int RecordsFetched { get; init; }

        public int RecordsPersisted { get; init; }

        public int RecordsUnchanged { get; init; }

        public int RecordsFailed { get; init; }

        public string? FailureReason { get; init; }

        public DateTimeOffset StartedAtUtc { get; init; }

        public DateTimeOffset? CompletedAtUtc { get; init; }
    }

    private sealed class ScheduleRow
    {
        public Guid PriceSourceId { get; init; }

        public string PriceSourceCode { get; init; } = string.Empty;

        public string PriceSourceName { get; init; } = string.Empty;

        public bool PriceSourceIsActive { get; init; }

        public string CategoryCode { get; init; } = string.Empty;

        public string CategoryName { get; init; } = string.Empty;

        public int CategoryDisplayOrder { get; init; }

        public Guid? ScheduleId { get; init; }

        public bool? IsEnabled { get; init; }

        public string? Frequency { get; init; }

        /// <summary>Formatted <c>HH:mm</c> in SQL, so no Dapper type handler is needed for <c>time</c>.</summary>
        public string? TimeOfDay { get; init; }

        public string? DayOfWeek { get; init; }

        public int? IntervalHours { get; init; }

        public DateTimeOffset? NextRunAtUtc { get; init; }

        public DateTimeOffset? LastRunAtUtc { get; init; }

        public Guid? LastJobId { get; init; }

        public string? LastJobTriggerType { get; init; }

        public string? LastJobStatus { get; init; }

        public DateOnly? LastJobAsOfDate { get; init; }

        public int? LastJobRecordsPersisted { get; init; }

        public int? LastJobRecordsUnchanged { get; init; }

        public int? LastJobRecordsFailed { get; init; }

        public string? LastJobFailureReason { get; init; }

        public DateTimeOffset? LastJobStartedAtUtc { get; init; }

        public DateTimeOffset? LastJobCompletedAtUtc { get; init; }
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
