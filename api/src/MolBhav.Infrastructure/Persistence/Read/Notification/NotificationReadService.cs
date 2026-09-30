using Dapper;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Notification.Models;
using MolBhav.Domain.Notification;
using MolBhav.Infrastructure.Persistence.Configurations.Notification;

namespace MolBhav.Infrastructure.Persistence.Read.Notification;

internal sealed class NotificationReadService(IDbConnectionFactory connectionFactory) : INotificationReadService
{
    private const string Notifications = Schemas.Notification + "." + NotificationMessageConfiguration.TableName;

    private const string MySql = $"""
        SELECT count(*) FROM {Notifications} n WHERE n.user_id = @UserId;

        SELECT n.id, n.channel, n.title, n.body, n.status, n.sent_at_utc, n.created_at_utc
        FROM {Notifications} n
        WHERE n.user_id = @UserId
        ORDER BY n.created_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    private const string AdminFrom = $"""
        FROM {Notifications} n
        """;

    private const string AdminWhere = """
        WHERE (@UserId::uuid IS NULL OR n.user_id = @UserId::uuid)
          AND (@Channel::text IS NULL OR n.channel = @Channel::text)
          AND (@Status::text IS NULL OR n.status = @Status::text)
        """;

    private static readonly string AdminSql = $"""
        SELECT count(*)
        {AdminFrom}
        {AdminWhere};

        SELECT n.id, n.user_id, n.channel, n.title, n.status, n.failure_reason, n.sent_at_utc, n.created_at_utc
        {AdminFrom}
        {AdminWhere}
        ORDER BY n.created_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    public async Task<PagedResult<NotificationResponse>> GetMyNotificationsAsync(Guid userId, PageRequest page, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(page);

        var args = new { UserId = userId, Limit = page.PageSize, Offset = page.Offset };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(MySql, args, cancellationToken));

        var totalCount = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<NotificationRow>();

        return new PagedResult<NotificationResponse>(
            rows.Select(r => new NotificationResponse(
                r.Id, Enum.Parse<NotificationChannel>(r.Channel), r.Title, r.Body,
                Enum.Parse<NotificationStatus>(r.Status), r.SentAtUtc, r.CreatedAtUtc)).ToArray(),
            page.Page, page.PageSize, totalCount);
    }

    public async Task<PagedResult<AdminNotificationResponse>> GetAdminNotificationsAsync(AdminNotificationFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("UserId", filter.UserId);
        args.Add("Channel", filter.Channel?.ToString());
        args.Add("Status", filter.Status?.ToString());
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminSql, args, cancellationToken));

        var totalCount = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<AdminNotificationRow>();

        return new PagedResult<AdminNotificationResponse>(
            rows.Select(r => new AdminNotificationResponse(
                r.Id, r.UserId, Enum.Parse<NotificationChannel>(r.Channel), r.Title,
                Enum.Parse<NotificationStatus>(r.Status), r.FailureReason, r.SentAtUtc, r.CreatedAtUtc)).ToArray(),
            filter.Page.Page, filter.Page.PageSize, totalCount);
    }

    private static CommandDefinition Command(string sql, object? args, CancellationToken cancellationToken) =>
        new(sql, args, cancellationToken: cancellationToken);

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class NotificationRow
    {
        public Guid Id { get; init; }

        public string Channel { get; init; } = string.Empty;

        public string Title { get; init; } = string.Empty;

        public string Body { get; init; } = string.Empty;

        public string Status { get; init; } = string.Empty;

        public DateTimeOffset? SentAtUtc { get; init; }

        public DateTimeOffset CreatedAtUtc { get; init; }
    }

    private sealed class AdminNotificationRow
    {
        public Guid Id { get; init; }

        public Guid UserId { get; init; }

        public string Channel { get; init; } = string.Empty;

        public string Title { get; init; } = string.Empty;

        public string Status { get; init; } = string.Empty;

        public string? FailureReason { get; init; }

        public DateTimeOffset? SentAtUtc { get; init; }

        public DateTimeOffset CreatedAtUtc { get; init; }
    }
#pragma warning restore CA1812
}
