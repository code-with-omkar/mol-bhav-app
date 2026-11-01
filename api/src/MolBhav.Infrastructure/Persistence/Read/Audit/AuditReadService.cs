using Dapper;
using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Audit.Models;

namespace MolBhav.Infrastructure.Persistence.Read.Audit;

internal sealed class AuditReadService(IDbConnectionFactory connectionFactory) : IAuditReadService
{
    private const string ListSql = """
        SELECT count(*) FROM platform.audit_entries e WHERE (@Action::text IS NULL OR e.action = @Action::text);

        SELECT e.id, e.occurred_at_utc, e.action, e.target, e.summary, e.actor_user_id,
               COALESCE(NULLIF(u.display_name, ''), u.phone_number) AS actor_name
        FROM platform.audit_entries e
        LEFT JOIN identity.users u ON u.id = e.actor_user_id
        WHERE (@Action::text IS NULL OR e.action = @Action::text)
        ORDER BY e.occurred_at_utc DESC, e.id
        LIMIT @Limit OFFSET @Offset;
        """;

    public async Task<PagedResult<AuditEntryResponse>> GetEntriesAsync(string? action, PageRequest page, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(page);

        var args = new DynamicParameters();
        args.Add("Action", action);
        args.Add("Limit", page.PageSize);
        args.Add("Offset", page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(new CommandDefinition(ListSql, args, cancellationToken: cancellationToken));

        var total = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<EntryRow>();

        return new PagedResult<AuditEntryResponse>(
            [.. rows.Select(r => new AuditEntryResponse(r.Id, r.OccurredAtUtc, r.Action, r.Target, r.Summary, r.ActorUserId, r.ActorName))],
            page.Page,
            page.PageSize,
            total);
    }

    private sealed record EntryRow(
        Guid Id,
        DateTimeOffset OccurredAtUtc,
        string Action,
        string? Target,
        string Summary,
        Guid ActorUserId,
        string? ActorName);
}
