using Dapper;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Localization.Models;
using MolBhav.Infrastructure.Persistence.Configurations.Localization;

namespace MolBhav.Infrastructure.Persistence.Read.Localization;

/// <summary>Localization reads for the admin portal (every translation) and the mobile app (one resolved string per key).</summary>
internal sealed class LocalizationReadService(IDbConnectionFactory connectionFactory) : ILocalizationReadService
{
    private const string Entries = Schemas.Localization + "." + LocalizedTextEntryConfiguration.TableName;
    private const string Translations = Schemas.Localization + "." + LocalizedTextEntryConfiguration.TranslationsTableName;

    private const string AdminTextsListWhere = "WHERE (@KeyPrefix::text IS NULL OR e.key LIKE @KeyPrefix || '%')";

    private static readonly string AdminTextsListSql = $"""
        SELECT count(*) FROM {Entries} e {AdminTextsListWhere};

        SELECT e.id, e.key, e.description
        FROM {Entries} e
        {AdminTextsListWhere}
        ORDER BY e.key
        LIMIT @Limit OFFSET @Offset;
        """;

    private const string AdminTextSql = $"""
        SELECT e.id, e.key, e.description FROM {Entries} e WHERE e.id = @Id;

        SELECT t.text_entry_id AS owner_id, t.language_code, t.text
        FROM {Translations} t
        WHERE t.text_entry_id = @Id
        ORDER BY t.language_code;
        """;

    /// <summary>One row per matched key: translation joined by language, falling back to English when missing.</summary>
    private static readonly string ResolvedTextsSql = $"""
        SELECT e.key, COALESCE(req.text, en.text) AS text
        FROM {Entries} e
        LEFT JOIN {Translations} req ON req.text_entry_id = e.id AND req.language_code = @Language
        LEFT JOIN {Translations} en ON en.text_entry_id = e.id AND en.language_code = 'en'
        WHERE (@KeyPrefix::text IS NULL OR e.key LIKE @KeyPrefix || '%');
        """;

    public async Task<PagedResult<AdminLocalizedTextResponse>> GetAdminTextsAsync(AdminLocalizedTextFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("KeyPrefix", filter.KeyPrefix);
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminTextsListSql, args, cancellationToken));

        var total = await grid.ReadSingleAsync<long>();
        var entries = (await grid.ReadAsync<EntryRow>()).AsList();

        var ids = entries.Select(e => e.Id).ToArray();
        var translations = await ReadTranslationsAsync(connection, ids, cancellationToken);

        var items = entries
            .Select(e => new AdminLocalizedTextResponse(e.Id, e.Key, e.Description, translations[e.Id].ToArray()))
            .ToArray();

        return new PagedResult<AdminLocalizedTextResponse>(items, filter.Page.Page, filter.Page.PageSize, total);
    }

    public async Task<AdminLocalizedTextResponse?> GetAdminTextAsync(Guid id, CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminTextSql, new { Id = id }, cancellationToken));

        var entry = await grid.ReadSingleOrDefaultAsync<EntryRow>();
        if (entry is null)
        {
            return null;
        }

        var translations = (await grid.ReadAsync<TranslationRow>())
            .Select(t => new LocalizedTextTranslationResponse(t.LanguageCode.Trim(), t.Text))
            .ToArray();

        return new AdminLocalizedTextResponse(entry.Id, entry.Key, entry.Description, translations);
    }

    public async Task<IReadOnlyDictionary<string, string>> GetTextsAsync(string languageCode, string? keyPrefix, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(languageCode);

        var args = new { Language = languageCode, KeyPrefix = keyPrefix };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<ResolvedTextRow>(Command(ResolvedTextsSql, args, cancellationToken));

        // English is enforced by the domain, so Text is null here only for an entry whose row hasn't committed yet;
        // skip it rather than surface a null value to callers.
        return rows
            .Where(r => r.Text is not null)
            .ToDictionary(r => r.Key, r => r.Text!, StringComparer.Ordinal);
    }

    private static async Task<ILookup<Guid, LocalizedTextTranslationResponse>> ReadTranslationsAsync(
        System.Data.Common.DbConnection connection,
        Guid[] ownerIds,
        CancellationToken cancellationToken)
    {
        if (ownerIds.Length == 0)
        {
            return Enumerable.Empty<TranslationRow>().ToLookup(t => t.OwnerId, t => new LocalizedTextTranslationResponse(t.LanguageCode, t.Text));
        }

        const string sql = $"""
            SELECT t.text_entry_id AS owner_id, t.language_code, t.text
            FROM {Translations} t
            WHERE t.text_entry_id = ANY(@OwnerIds)
            ORDER BY t.language_code;
            """;

        var rows = await connection.QueryAsync<TranslationRow>(Command(sql, new { OwnerIds = ownerIds }, cancellationToken));
        return rows.ToLookup(t => t.OwnerId, t => new LocalizedTextTranslationResponse(t.LanguageCode.Trim(), t.Text));
    }

    private static CommandDefinition Command(string sql, object? args, CancellationToken cancellationToken) =>
        new(sql, args, cancellationToken: cancellationToken);

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class EntryRow
    {
        public Guid Id { get; init; }

        public string Key { get; init; } = string.Empty;

        public string? Description { get; init; }
    }

    private sealed class TranslationRow
    {
        public Guid OwnerId { get; init; }

        public string LanguageCode { get; init; } = string.Empty;

        public string Text { get; init; } = string.Empty;
    }

    private sealed class ResolvedTextRow
    {
        public string Key { get; init; } = string.Empty;

        public string? Text { get; init; }
    }
#pragma warning restore CA1812
}
