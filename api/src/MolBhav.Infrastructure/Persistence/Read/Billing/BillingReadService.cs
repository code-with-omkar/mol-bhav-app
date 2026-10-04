using System.Text.Json;
using Dapper;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Billing;
using MolBhav.Infrastructure.Billing.Webhooks;
using MolBhav.Infrastructure.Persistence.Configurations.Billing;

namespace MolBhav.Infrastructure.Persistence.Read.Billing;

internal sealed class BillingReadService(IDbConnectionFactory connectionFactory) : IBillingReadService
{
    private const string Plans = Schemas.Billing + "." + PlanConfiguration.TableName;
    private const string Subscriptions = Schemas.Billing + "." + SubscriptionConfiguration.TableName;
    private const string Coupons = Schemas.Billing + "." + CouponConfiguration.TableName;
    private const string Webhooks = WebhookInboxMessageConfiguration.QualifiedTableName;

    // State is derived from the two timestamps (parked wins: a row is never both).
    private const string WebhookColumns = """
        w.id, w.provider, w.event_id, w.event_type,
        CASE WHEN w.parked_at_utc IS NOT NULL THEN 'Parked'
             WHEN w.processed_at_utc IS NOT NULL THEN 'Processed'
             ELSE 'Pending' END AS state,
        w.attempt_count, w.received_at_utc, w.next_attempt_at_utc, w.last_attempt_at_utc,
        w.processed_at_utc, w.parked_at_utc, w.last_error
        """;

    private const string AdminWebhooksWhere = """
        WHERE (@State::text IS NULL
               OR (@State::text = 'Parked' AND w.parked_at_utc IS NOT NULL)
               OR (@State::text = 'Processed' AND w.processed_at_utc IS NOT NULL)
               OR (@State::text = 'Pending' AND w.processed_at_utc IS NULL AND w.parked_at_utc IS NULL))
          AND (@EventType::text IS NULL OR w.event_type = @EventType::text)
        """;

    // Admin-only, low volume (rows are purged after the retention period): no dedicated index on received_at_utc;
    // the Parked/Pending filters still hit the inbox's partial indexes.
    private static readonly string AdminWebhooksSql = $"""
        SELECT count(*) FROM {Webhooks} w
        {AdminWebhooksWhere};

        SELECT {WebhookColumns}
        FROM {Webhooks} w
        {AdminWebhooksWhere}
        ORDER BY w.received_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    private static readonly string AdminWebhookSql = $"""
        SELECT {WebhookColumns}, w.payload::text AS payload
        FROM {Webhooks} w
        WHERE w.id = @Id;
        """;

    private const string AdminCouponsSql = $"""
        SELECT count(*) FROM {Coupons};

        SELECT c.id, c.code, c.discount_type, c.discount_value, c.max_uses, c.uses_count,
               c.valid_from, c.valid_to, c.applicable_plan_code, c.min_amount_paise, c.is_active
        FROM {Coupons} c
        ORDER BY c.created_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    private const string ActivePlansSql = $"""
        SELECT p.id, p.code, p.name, p.price, p.currency, p.billing_period
        FROM {Plans} p
        WHERE p.is_active
        ORDER BY p.price;
        """;

    private const string AdminPlansSql = $"""
        SELECT p.id, p.code, p.name, p.price, p.currency, p.billing_period, p.is_active
        FROM {Plans} p
        ORDER BY p.name;
        """;

    private const string MySubscriptionSql = $"""
        SELECT s.id, s.plan_id, p.code AS plan_code, p.name AS plan_name, s.status, s.billing_cycle,
               s.started_at_utc, s.expires_at_utc, s.is_auto_renew, s.cancelled_at_utc
        FROM {Subscriptions} s
        JOIN {Plans} p ON p.id = s.plan_id
        WHERE s.user_id = @UserId
        ORDER BY s.started_at_utc DESC
        LIMIT 1;
        """;

    private const string AdminSubscriptionsFrom = $"""
        FROM {Subscriptions} s
        JOIN {Plans} p ON p.id = s.plan_id
        """;

    private const string AdminSubscriptionsWhere = """
        WHERE (@UserId::uuid IS NULL OR s.user_id = @UserId::uuid)
          AND (@Status::text IS NULL OR s.status = @Status::text)
        """;

    private static readonly string AdminSubscriptionsSql = $"""
        SELECT count(*)
        {AdminSubscriptionsFrom}
        {AdminSubscriptionsWhere};

        SELECT s.id, s.user_id, s.plan_id, p.code AS plan_code, s.status,
               s.started_at_utc, s.expires_at_utc, s.is_auto_renew, s.cancelled_at_utc
        {AdminSubscriptionsFrom}
        {AdminSubscriptionsWhere}
        ORDER BY s.started_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    public async Task<IReadOnlyList<PlanResponse>> GetActivePlansAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<PlanRow>(Command(ActivePlansSql, null, cancellationToken));

        return rows.Select(r => new PlanResponse(r.Id, r.Code, r.Name, r.Price, r.Currency, Enum.Parse<BillingPeriod>(r.BillingPeriod))).ToArray();
    }

    public async Task<IReadOnlyList<AdminPlanResponse>> GetAdminPlansAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<AdminPlanRow>(Command(AdminPlansSql, null, cancellationToken));

        return rows
            .Select(r => new AdminPlanResponse(r.Id, r.Code, r.Name, r.Price, r.Currency, Enum.Parse<BillingPeriod>(r.BillingPeriod), r.IsActive))
            .ToArray();
    }

    public async Task<SubscriptionResponse?> GetMySubscriptionAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var args = new { UserId = userId };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var row = await connection.QuerySingleOrDefaultAsync<SubscriptionRow>(Command(MySubscriptionSql, args, cancellationToken));

        return row is null
            ? null
            : new SubscriptionResponse(
                row.Id, row.PlanId, row.PlanCode, row.PlanName, Enum.Parse<SubscriptionStatus>(row.Status),
                Enum.Parse<BillingPeriod>(row.BillingCycle), row.StartedAtUtc, row.ExpiresAtUtc, row.IsAutoRenew, row.CancelledAtUtc);
    }

    public async Task<PagedResult<AdminSubscriptionResponse>> GetAdminSubscriptionsAsync(AdminSubscriptionFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("UserId", filter.UserId);
        args.Add("Status", filter.Status?.ToString());
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminSubscriptionsSql, args, cancellationToken));

        var totalCount = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<AdminSubscriptionRow>();

        return new PagedResult<AdminSubscriptionResponse>(
            rows.Select(r => new AdminSubscriptionResponse(
                r.Id, r.UserId, r.PlanId, r.PlanCode, Enum.Parse<SubscriptionStatus>(r.Status),
                r.StartedAtUtc, r.ExpiresAtUtc, r.IsAutoRenew, r.CancelledAtUtc)).ToArray(),
            filter.Page.Page, filter.Page.PageSize, totalCount);
    }

    public async Task<PagedResult<AdminCouponResponse>> GetAdminCouponsAsync(PageRequest page, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(page);

        var args = new { Limit = page.PageSize, page.Offset };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminCouponsSql, args, cancellationToken));

        var totalCount = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<AdminCouponRow>();

        return new PagedResult<AdminCouponResponse>(
            rows.Select(r => new AdminCouponResponse(
                r.Id, r.Code, Enum.Parse<DiscountType>(r.DiscountType), r.DiscountValue, r.MaxUses, r.UsesCount,
                r.ValidFrom, r.ValidTo, r.ApplicablePlanCode, r.MinAmountPaise, r.IsActive)).ToArray(),
            page.Page, page.PageSize, totalCount);
    }

    private static CommandDefinition Command(string sql, object? args, CancellationToken cancellationToken) =>
        new(sql, args, cancellationToken: cancellationToken);

    public async Task<PagedResult<AdminWebhookResponse>> GetAdminWebhooksAsync(AdminWebhookFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("State", filter.State?.ToString());
        args.Add("EventType", string.IsNullOrWhiteSpace(filter.EventType) ? null : filter.EventType.Trim());
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminWebhooksSql, args, cancellationToken));

        var totalCount = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<WebhookRow>();

        return new PagedResult<AdminWebhookResponse>(rows.Select(ToResponse).ToArray(), filter.Page.Page, filter.Page.PageSize, totalCount);
    }

    public async Task<AdminWebhookDetailResponse?> GetAdminWebhookAsync(Guid id, CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var row = await connection.QuerySingleOrDefaultAsync<WebhookRow>(Command(AdminWebhookSql, new { Id = id }, cancellationToken));

        if (row is null)
        {
            return null;
        }

        // jsonb always holds valid JSON; Clone detaches the element from the disposed document.
        using var payload = JsonDocument.Parse(row.Payload ?? "null");
        return new AdminWebhookDetailResponse(ToResponse(row), payload.RootElement.Clone());
    }

    private static AdminWebhookResponse ToResponse(WebhookRow r) =>
        new(r.Id, r.Provider, r.EventId, r.EventType, Enum.Parse<WebhookInboxState>(r.State), r.AttemptCount,
            r.ReceivedAtUtc, r.NextAttemptAtUtc, r.LastAttemptAtUtc, r.ProcessedAtUtc, r.ParkedAtUtc, r.LastError);

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class PlanRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public decimal Price { get; init; }

        public string Currency { get; init; } = string.Empty;

        public string BillingPeriod { get; init; } = string.Empty;
    }

    private sealed class AdminPlanRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public decimal Price { get; init; }

        public string Currency { get; init; } = string.Empty;

        public string BillingPeriod { get; init; } = string.Empty;

        public bool IsActive { get; init; }
    }

    private sealed class SubscriptionRow
    {
        public Guid Id { get; init; }

        public Guid PlanId { get; init; }

        public string PlanCode { get; init; } = string.Empty;

        public string PlanName { get; init; } = string.Empty;

        public string Status { get; init; } = string.Empty;

        public string BillingCycle { get; init; } = string.Empty;

        public DateTimeOffset StartedAtUtc { get; init; }

        public DateTimeOffset ExpiresAtUtc { get; init; }

        public bool IsAutoRenew { get; init; }

        public DateTimeOffset? CancelledAtUtc { get; init; }
    }

    private sealed class AdminSubscriptionRow
    {
        public Guid Id { get; init; }

        public Guid UserId { get; init; }

        public Guid PlanId { get; init; }

        public string PlanCode { get; init; } = string.Empty;

        public string Status { get; init; } = string.Empty;

        public DateTimeOffset StartedAtUtc { get; init; }

        public DateTimeOffset ExpiresAtUtc { get; init; }

        public bool IsAutoRenew { get; init; }

        public DateTimeOffset? CancelledAtUtc { get; init; }
    }
    private sealed class AdminCouponRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string DiscountType { get; init; } = string.Empty;

        public long DiscountValue { get; init; }

        public int? MaxUses { get; init; }

        public int UsesCount { get; init; }

        public DateTimeOffset ValidFrom { get; init; }

        public DateTimeOffset? ValidTo { get; init; }

        public string? ApplicablePlanCode { get; init; }

        public long MinAmountPaise { get; init; }

        public bool IsActive { get; init; }
    }

    private sealed class WebhookRow
    {
        public Guid Id { get; init; }

        public string Provider { get; init; } = string.Empty;

        public string EventId { get; init; } = string.Empty;

        public string EventType { get; init; } = string.Empty;

        public string State { get; init; } = string.Empty;

        public int AttemptCount { get; init; }

        public DateTimeOffset ReceivedAtUtc { get; init; }

        public DateTimeOffset NextAttemptAtUtc { get; init; }

        public DateTimeOffset? LastAttemptAtUtc { get; init; }

        public DateTimeOffset? ProcessedAtUtc { get; init; }

        public DateTimeOffset? ParkedAtUtc { get; init; }

        public string? LastError { get; init; }

        /// <summary>Only selected by the detail query.</summary>
        public string? Payload { get; init; }
    }
#pragma warning restore CA1812
}
