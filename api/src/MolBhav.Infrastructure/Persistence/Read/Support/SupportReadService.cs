using Dapper;
using MolBhav.Application.Abstractions.Support;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Support.Models;
using MolBhav.Domain.Support;
using MolBhav.Infrastructure.Persistence.Configurations.Identity;
using MolBhav.Infrastructure.Persistence.Configurations.Support;

namespace MolBhav.Infrastructure.Persistence.Read.Support;

internal sealed class SupportReadService(IDbConnectionFactory connectionFactory) : ISupportReadService
{
    private const string Tickets = Schemas.Support + "." + SupportTicketConfiguration.TableName;
    private const string Messages = Schemas.Support + "." + SupportTicketMessageConfiguration.TableName;
    private const string Users = UserConfiguration.QualifiedTableName;

    private const string MessageCount = $"(SELECT count(*) FROM {Messages} m WHERE m.ticket_id = t.id) AS message_count";

    private static readonly string MySql = $"""
        SELECT count(*) FROM {Tickets} t WHERE t.user_id = @UserId;

        SELECT t.id, t.category, t.subject, t.status, t.created_at_utc, t.last_activity_at_utc,
               {MessageCount}
        FROM {Tickets} t
        WHERE t.user_id = @UserId
        ORDER BY t.last_activity_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    private static readonly string OneSql = $"""
        SELECT t.id, t.category, t.subject, t.status, t.created_at_utc, t.last_activity_at_utc
        FROM {Tickets} t
        WHERE t.id = @TicketId AND (@UserId::uuid IS NULL OR t.user_id = @UserId::uuid);

        SELECT m.id, m.author_kind, m.body, m.created_at_utc
        FROM {Messages} m
        JOIN {Tickets} t ON t.id = m.ticket_id
        WHERE m.ticket_id = @TicketId AND (@UserId::uuid IS NULL OR t.user_id = @UserId::uuid)
        ORDER BY m.created_at_utc, m.id;
        """;

    private const string AdminFrom = $"""
        FROM {Tickets} t
        JOIN {Users} u ON u.id = t.user_id
        """;

    private const string AdminWhere = """
        WHERE (@Status::text IS NULL OR t.status = @Status::text)
          AND (@Category::text IS NULL OR t.category = @Category::text)
          AND (@Search::text IS NULL OR t.subject ILIKE '%' || @Search::text || '%')
        """;

    private static readonly string AdminSql = $"""
        SELECT count(*)
        {AdminFrom}
        {AdminWhere};

        SELECT t.id, t.user_id,
               '******' || right(u.phone_number, 4) AS phone_number_masked,
               t.category, t.subject, t.status,
               t.created_at_utc, t.last_activity_at_utc,
               {MessageCount}
        {AdminFrom}
        {AdminWhere}
        ORDER BY t.last_activity_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    public async Task<PagedResult<SupportTicketSummaryResponse>> GetMyTicketsAsync(
        Guid userId,
        PageRequest page,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(page);

        var args = new { UserId = userId, Limit = page.PageSize, Offset = page.Offset };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(MySql, args, cancellationToken));

        var totalCount = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<TicketRow>();

        return new PagedResult<SupportTicketSummaryResponse>(
            rows.Select(ToSummaryResponse).ToArray(), page.Page, page.PageSize, totalCount);
    }

    public async Task<SupportTicketResponse?> GetTicketAsync(Guid ticketId, Guid? userId, CancellationToken cancellationToken = default)
    {
        var args = new DynamicParameters();
        args.Add("TicketId", ticketId);
        args.Add("UserId", userId);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(OneSql, args, cancellationToken));

        var ticket = await grid.ReadSingleOrDefaultAsync<TicketRow>();
        if (ticket is null)
        {
            return null;
        }

        var messages = await grid.ReadAsync<MessageRow>();

        return new SupportTicketResponse(
            ticket.Id,
            Enum.Parse<SupportTicketCategory>(ticket.Category),
            ticket.Subject,
            Enum.Parse<SupportTicketStatus>(ticket.Status),
            ticket.CreatedAtUtc,
            ticket.LastActivityAtUtc,
            messages.Select(m => new SupportTicketMessageResponse(
                m.Id,
                Enum.Parse<SupportMessageAuthorKind>(m.AuthorKind),
                m.Body,
                m.CreatedAtUtc)).ToArray());
    }

    public async Task<PagedResult<AdminSupportTicketResponse>> GetAdminTicketsAsync(
        AdminSupportTicketFilter filter,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("Status", filter.Status?.ToString());
        args.Add("Category", filter.Category?.ToString());
        args.Add("Search", string.IsNullOrWhiteSpace(filter.Search) ? null : filter.Search.Trim());
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminSql, args, cancellationToken));

        var totalCount = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<AdminTicketRow>();

        return new PagedResult<AdminSupportTicketResponse>(
            rows.Select(r => new AdminSupportTicketResponse(
                r.Id,
                r.UserId,
                r.PhoneNumberMasked,
                Enum.Parse<SupportTicketCategory>(r.Category),
                r.Subject,
                Enum.Parse<SupportTicketStatus>(r.Status),
                r.MessageCount,
                r.CreatedAtUtc,
                r.LastActivityAtUtc)).ToArray(),
            filter.Page.Page,
            filter.Page.PageSize,
            totalCount);
    }

    private static SupportTicketSummaryResponse ToSummaryResponse(TicketRow r) => new(
        r.Id,
        Enum.Parse<SupportTicketCategory>(r.Category),
        r.Subject,
        Enum.Parse<SupportTicketStatus>(r.Status),
        r.MessageCount,
        r.CreatedAtUtc,
        r.LastActivityAtUtc);

    private static CommandDefinition Command(string sql, object? args, CancellationToken cancellationToken) =>
        new(sql, args, cancellationToken: cancellationToken);

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class TicketRow
    {
        public Guid Id { get; init; }

        public string Category { get; init; } = string.Empty;

        public string Subject { get; init; } = string.Empty;

        public string Status { get; init; } = string.Empty;

        public int MessageCount { get; init; }

        public DateTimeOffset CreatedAtUtc { get; init; }

        public DateTimeOffset LastActivityAtUtc { get; init; }
    }

    private sealed class AdminTicketRow
    {
        public Guid Id { get; init; }

        public Guid UserId { get; init; }

        public string PhoneNumberMasked { get; init; } = string.Empty;

        public string Category { get; init; } = string.Empty;

        public string Subject { get; init; } = string.Empty;

        public string Status { get; init; } = string.Empty;

        public int MessageCount { get; init; }

        public DateTimeOffset CreatedAtUtc { get; init; }

        public DateTimeOffset LastActivityAtUtc { get; init; }
    }

    private sealed class MessageRow
    {
        public Guid Id { get; init; }

        public string AuthorKind { get; init; } = string.Empty;

        public string Body { get; init; } = string.Empty;

        public DateTimeOffset CreatedAtUtc { get; init; }
    }
#pragma warning restore CA1812
}
