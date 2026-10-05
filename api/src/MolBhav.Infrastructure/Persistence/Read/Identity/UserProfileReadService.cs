using Dapper;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Infrastructure.Persistence.Configurations.Catalog;
using MolBhav.Infrastructure.Persistence.Configurations.Identity;
using MolBhav.Infrastructure.Persistence.Configurations.Market;

namespace MolBhav.Infrastructure.Persistence.Read.Identity;

/// <summary>
/// Profile screen read model. Two round-trips in one batch (Dapper <c>QueryMultiple</c>): the user row by primary key
/// (with its stored state/district resolved against the market master), and its categories with localized names.
/// Masking happens in SQL so the full phone number never leaves the database for this screen.
/// </summary>
internal sealed class UserProfileReadService(IDbConnectionFactory connectionFactory) : IUserProfileReadService
{
    private const string States = Schemas.Market + "." + StateConfiguration.TableName;
    private const string Districts = Schemas.Market + "." + DistrictConfiguration.TableName;
    private const string Categories = Schemas.Catalog + "." + ProcurementCategoryConfiguration.TableName;
    private const string CategoryTranslations = Schemas.Catalog + "." + ProcurementCategoryConfiguration.TranslationsTableName;

    // State/district are stored as the picker's keys (state code, district name); older rows may hold the state name.
    private const string Sql = $"""
        SELECT u.id                                                         AS user_id,
               '******' || right(u.phone_number, 4)                         AS phone_number_masked,
               u.display_name,
               u.preferred_language,
               lower(u.subscription_tier)                                   AS subscription_tier,
               u.business_type,
               u.state,
               u.district,
               s.id                                                         AS state_id,
               s.code                                                       AS state_code,
               s.name                                                       AS state_name,
               d.id                                                         AS district_id,
               d.name                                                       AS district_name,
               false                                                        AS push_enabled,
               false                                                        AS whats_app_enabled,
               u.last_login_at_utc,
               u.created_at_utc,
               u.password_hash IS NOT NULL                                  AS has_password,
               g.user_id IS NOT NULL                                        AS has_google_login,
               g.email                                                      AS google_email
        FROM {UserConfiguration.QualifiedTableName} u
        LEFT JOIN {UserConfiguration.QualifiedExternalLoginsTableName} g
               ON g.user_id = u.id AND g.provider = 'Google'
        LEFT JOIN LATERAL (
            SELECT st.id, st.code, st.name
            FROM {States} st
            WHERE upper(st.code) = upper(u.state) OR lower(st.name) = lower(u.state)
            ORDER BY (upper(st.code) = upper(u.state)) DESC
            LIMIT 1
        ) s ON TRUE
        LEFT JOIN LATERAL (
            SELECT dt.id, dt.name
            FROM {Districts} dt
            WHERE dt.state_id = s.id AND lower(dt.name) = lower(u.district)
            LIMIT 1
        ) d ON TRUE
        WHERE u.id = @UserId
          AND u.is_deleted = false;

        SELECT uc.category_code AS code, coalesce(cn.name, uc.category_code) AS name
        FROM {UserConfiguration.QualifiedCategoriesTableName} uc
        LEFT JOIN {Categories} c ON c.code = uc.category_code
        LEFT JOIN LATERAL (
            SELECT t.name
            FROM {CategoryTranslations} t
            WHERE t.category_id = c.id AND t.language_code IN (@Lang, @DefaultLang, 'en')
            ORDER BY CASE t.language_code WHEN @Lang THEN 0 WHEN @DefaultLang THEN 1 ELSE 2 END
            LIMIT 1
        ) cn ON TRUE
        WHERE uc.user_id = @UserId
        ORDER BY c.display_order NULLS LAST, uc.category_code;
        """;

    public async Task<UserProfileReadModel?> GetByUserIdAsync(
        Guid userId, LanguagePreference language, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(language);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);

        await using var results = await connection.QueryMultipleAsync(new CommandDefinition(
            Sql,
            new { UserId = userId, Lang = language.Requested, DefaultLang = language.Default },
            cancellationToken: cancellationToken));

        var row = await results.ReadSingleOrDefaultAsync<UserRow>();
        if (row is null)
        {
            return null;
        }

        var categories = (await results.ReadAsync<CategoryRow>())
            .Select(c => new ProfileCategoryReadModel(c.Code, c.Name))
            .ToList();

        return new UserProfileReadModel(
            row.UserId,
            row.PhoneNumberMasked,
            row.DisplayName,
            row.PreferredLanguage.Trim(),
            row.SubscriptionTier,
            row.BusinessType,
            row.State,
            row.District,
            row.StateId,
            row.StateCode,
            row.StateName,
            row.DistrictId,
            row.DistrictName,
            [.. categories.Select(c => c.Code)],
            categories,
            row.PushEnabled,
            row.WhatsAppEnabled,
            row.LastLoginAtUtc is { } lastLogin ? AsUtc(lastLogin) : null,
            AsUtc(row.CreatedAtUtc),
            row.HasPassword,
            row.HasGoogleLogin,
            row.GoogleEmail);
    }

    /// <summary>Npgsql hands <c>timestamptz</c> to Dapper as a UTC <see cref="DateTime"/>; Dapper cannot convert that to <see cref="DateTimeOffset"/> itself.</summary>
    private static DateTimeOffset AsUtc(DateTime value) => new(DateTime.SpecifyKind(value, DateTimeKind.Utc));

    /// <summary>Flat row shape for Dapper (snake_case → PascalCase via <c>MatchNamesWithUnderscores</c>).</summary>
    private sealed class UserRow
    {
        public Guid UserId { get; init; }

        public string PhoneNumberMasked { get; init; } = string.Empty;

        public string? DisplayName { get; init; }

        public string PreferredLanguage { get; init; } = string.Empty;

        public string SubscriptionTier { get; init; } = string.Empty;

        public string? BusinessType { get; init; }

        public string? State { get; init; }

        public string? District { get; init; }

        public Guid? StateId { get; init; }

        public string? StateCode { get; init; }

        public string? StateName { get; init; }

        public Guid? DistrictId { get; init; }

        public string? DistrictName { get; init; }

        public bool PushEnabled { get; init; }

        public bool WhatsAppEnabled { get; init; }

        public DateTime? LastLoginAtUtc { get; init; }

        public DateTime CreatedAtUtc { get; init; }

        public bool HasPassword { get; init; }

        public bool HasGoogleLogin { get; init; }

        public string? GoogleEmail { get; init; }
    }

    private sealed class CategoryRow
    {
        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;
    }
}
