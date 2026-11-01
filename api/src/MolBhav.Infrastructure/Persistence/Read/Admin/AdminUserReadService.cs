using Dapper;
using MolBhav.Application.Abstractions.Admin;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Admin.Models;
using MolBhav.Domain.Identity;

namespace MolBhav.Infrastructure.Persistence.Read.Admin;

internal sealed class AdminUserReadService(IDbConnectionFactory connectionFactory) : IAdminUserReadService
{
    private const string UserColumns = """
        u.id, u.phone_number, u.display_name, u.role, u.status, u.subscription_tier, u.state, u.district,
        u.business_type, u.last_login_at_utc, u.created_at_utc
        """;

    // Search is a case-insensitive "contains" on the phone number or name; % _ \ in the text are escaped by the caller.
    private const string ListWhere = """
        WHERE NOT u.is_deleted
          AND (@Status::text IS NULL OR u.status = @Status::text)
          AND (@Tier::text IS NULL OR u.subscription_tier = @Tier::text)
          AND (@Search::text IS NULL
               OR u.phone_number ILIKE '%' || @Search::text || '%' ESCAPE '\'
               OR u.display_name ILIKE '%' || @Search::text || '%' ESCAPE '\')
        """;

    private static readonly string ListSql = $"""
        SELECT count(*) FROM identity.users u {ListWhere};

        SELECT {UserColumns}
        FROM identity.users u
        {ListWhere}
        ORDER BY u.created_at_utc DESC, u.id
        LIMIT @Limit OFFSET @Offset;
        """;

    // The latest subscription is the one that started last; plans are looked up for their display name.
    private static readonly string DetailSql = $"""
        SELECT {UserColumns} FROM identity.users u WHERE u.id = @UserId AND NOT u.is_deleted;

        SELECT category_code FROM identity.user_categories WHERE user_id = @UserId ORDER BY category_code;

        SELECT p.name AS plan_name, s.status, s.expires_at_utc
        FROM billing.subscriptions s
        JOIN billing.plans p ON p.id = s.plan_id
        WHERE s.user_id = @UserId
        ORDER BY s.started_at_utc DESC
        LIMIT 1;

        SELECT count(*)::int AS total, (count(*) FILTER (WHERE status IN ('Open', 'InProgress')))::int AS open
        FROM support.support_tickets
        WHERE user_id = @UserId;
        """;

    public async Task<PagedResult<AdminUserResponse>> GetUsersAsync(AdminUserFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("Status", filter.Status?.ToString());
        args.Add("Tier", filter.Tier?.ToString());
        args.Add("Search", string.IsNullOrWhiteSpace(filter.Search) ? null : EscapeLike(filter.Search));
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(new CommandDefinition(ListSql, args, cancellationToken: cancellationToken));

        var total = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<UserRow>();

        return new PagedResult<AdminUserResponse>(rows.Select(ToResponse).ToArray(), filter.Page.Page, filter.Page.PageSize, total);
    }

    public async Task<AdminUserDetailResponse?> GetUserAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(
            new CommandDefinition(DetailSql, new { UserId = userId }, cancellationToken: cancellationToken));

        var user = await grid.ReadSingleOrDefaultAsync<UserRow>();
        if (user is null)
        {
            return null;
        }

        var categories = (await grid.ReadAsync<string>()).ToArray();
        var subscription = await grid.ReadSingleOrDefaultAsync<SubscriptionRow>();
        var tickets = await grid.ReadSingleAsync<TicketRow>();

        return new AdminUserDetailResponse(
            ToResponse(user),
            categories,
            subscription is null ? null : new AdminUserSubscriptionResponse(subscription.PlanName, subscription.Status, subscription.ExpiresAtUtc),
            tickets.Total,
            tickets.Open);
    }

    /// <summary>Makes <c>%</c>, <c>_</c> and the escape character match literally in an <c>ILIKE</c> pattern.</summary>
    private static string EscapeLike(string text) =>
        text.Replace("\\", "\\\\", StringComparison.Ordinal).Replace("%", "\\%", StringComparison.Ordinal).Replace("_", "\\_", StringComparison.Ordinal);

    private static AdminUserResponse ToResponse(UserRow r) => new(
        r.Id,
        r.PhoneNumber,
        r.DisplayName,
        Enum.Parse<UserRole>(r.Role),
        Enum.Parse<UserStatus>(r.Status),
        Enum.Parse<SubscriptionTier>(r.SubscriptionTier),
        r.State,
        r.District,
        r.BusinessType,
        r.LastLoginAtUtc,
        r.CreatedAtUtc);

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class UserRow
    {
        public Guid Id { get; init; }

        public string PhoneNumber { get; init; } = string.Empty;

        public string? DisplayName { get; init; }

        public string Role { get; init; } = string.Empty;

        public string Status { get; init; } = string.Empty;

        public string SubscriptionTier { get; init; } = string.Empty;

        public string? State { get; init; }

        public string? District { get; init; }

        public string? BusinessType { get; init; }

        public DateTimeOffset? LastLoginAtUtc { get; init; }

        public DateTimeOffset CreatedAtUtc { get; init; }
    }

    private sealed class SubscriptionRow
    {
        public string PlanName { get; init; } = string.Empty;

        public string Status { get; init; } = string.Empty;

        public DateTimeOffset ExpiresAtUtc { get; init; }
    }

    private sealed class TicketRow
    {
        public int Total { get; init; }

        public int Open { get; init; }
    }
}
