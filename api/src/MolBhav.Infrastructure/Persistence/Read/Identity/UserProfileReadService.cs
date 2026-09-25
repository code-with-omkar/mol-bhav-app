using Dapper;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Infrastructure.Persistence.Configurations.Identity;

namespace MolBhav.Infrastructure.Persistence.Read.Identity;

/// <summary>
/// Profile screen read model. Two round-trips in one batch (Dapper <c>QueryMultiple</c>): the user row by primary key,
/// and its categories by the composite PK prefix (user_id) — both index seeks. Masking happens in SQL so the full
/// phone number never leaves the database for this screen.
/// </summary>
internal sealed class UserProfileReadService(IDbConnectionFactory connectionFactory) : IUserProfileReadService
{
    private const string Sql = $"""
        SELECT u.id                                                  AS user_id,
               '******' || right(u.phone_number, 4)                  AS phone_number_masked,
               u.preferred_language,
               lower(u.subscription_tier)                            AS subscription_tier,
               u.business_type,
               u.state,
               u.district,
               u.last_login_at_utc,
               u.created_at_utc
        FROM {UserConfiguration.QualifiedTableName} u
        WHERE u.id = @UserId
          AND u.is_deleted = false;

        SELECT c.category_code
        FROM {UserConfiguration.QualifiedCategoriesTableName} c
        WHERE c.user_id = @UserId
        ORDER BY c.category_code;
        """;

    public async Task<UserProfileReadModel?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);

        await using var results = await connection.QueryMultipleAsync(
            new CommandDefinition(Sql, new { UserId = userId }, cancellationToken: cancellationToken));

        var row = await results.ReadSingleOrDefaultAsync<UserRow>();
        if (row is null)
        {
            return null;
        }

        var categories = (await results.ReadAsync<string>()).AsList();

        return new UserProfileReadModel(
            row.UserId,
            row.PhoneNumberMasked,
            row.PreferredLanguage.Trim(),
            row.SubscriptionTier,
            row.BusinessType,
            row.State,
            row.District,
            categories,
            row.LastLoginAtUtc is { } lastLogin ? AsUtc(lastLogin) : null,
            AsUtc(row.CreatedAtUtc));
    }

    /// <summary>Npgsql hands <c>timestamptz</c> to Dapper as a UTC <see cref="DateTime"/>; Dapper cannot convert that to <see cref="DateTimeOffset"/> itself.</summary>
    private static DateTimeOffset AsUtc(DateTime value) => new(DateTime.SpecifyKind(value, DateTimeKind.Utc));

    /// <summary>Flat row shape for Dapper (snake_case → PascalCase via <c>MatchNamesWithUnderscores</c>).</summary>
    private sealed class UserRow
    {
        public Guid UserId { get; init; }

        public string PhoneNumberMasked { get; init; } = string.Empty;

        public string PreferredLanguage { get; init; } = string.Empty;

        public string SubscriptionTier { get; init; } = string.Empty;

        public string? BusinessType { get; init; }

        public string? State { get; init; }

        public string? District { get; init; }

        public DateTime? LastLoginAtUtc { get; init; }

        public DateTime CreatedAtUtc { get; init; }
    }
}
