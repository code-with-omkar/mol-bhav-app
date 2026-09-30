using Dapper;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Watchlist;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Watchlist.Models;
using MolBhav.Infrastructure.Persistence.Configurations.Catalog;
using MolBhav.Infrastructure.Persistence.Configurations.Pricing;
using MolBhav.Infrastructure.Persistence.Configurations.Watchlist;

namespace MolBhav.Infrastructure.Persistence.Read.Watchlist;

/// <summary>Reuses catalog's language-fallback lateral-join pattern to name each watched product/variant, enriched with the latest price per product.</summary>
internal sealed class WatchlistReadService(IDbConnectionFactory connectionFactory) : IWatchlistReadService
{
    private const string WatchlistItems = Schemas.Watchlist + "." + WatchlistItemConfiguration.TableName;
    private const string Products = Schemas.Catalog + "." + ProductConfiguration.TableName;
    private const string ProductTranslations = Schemas.Catalog + "." + ProductConfiguration.TranslationsTableName;
    private const string Variants = Schemas.Catalog + "." + ProductVariantConfiguration.TableName;
    private const string VariantTranslations = Schemas.Catalog + "." + ProductVariantConfiguration.TranslationsTableName;
    private const string SubCategories = Schemas.Catalog + "." + SubCategoryConfiguration.TableName;
    private const string SubCategoryTranslations = Schemas.Catalog + "." + SubCategoryConfiguration.TranslationsTableName;
    private const string Units = Schemas.Catalog + "." + UnitOfMeasureConfiguration.TableName;
    private const string UnitTranslations = Schemas.Catalog + "." + UnitOfMeasureConfiguration.TranslationsTableName;
    private const string PriceRecords = Schemas.Pricing + "." + PriceRecordConfiguration.TableName;

    private static readonly string ProductName = NameLateral(ProductTranslations, "product_id", "p", "pn");
    private static readonly string SubCategoryName = NameLateral(SubCategoryTranslations, "sub_category_id", "s", "sn");
    private static readonly string UnitName = NameLateral(UnitTranslations, "unit_id", "u", "un");
    private static readonly string VariantName = NameLateral(VariantTranslations, "variant_id", "v", "vn");

    private static readonly string WatchlistSql = $"""
        SELECT w.id, w.variant_id, w.created_at_utc,
               p.id AS product_id, p.code AS product_code, pn.name AS product_name,
               p.sub_category_id, sn.name AS sub_category_name,
               u.id AS unit_id, u.code AS unit_code, u.symbol AS unit_symbol, un.name AS unit_name,
               p.image_key, vn.name AS variant_name,
               lp.modal_price AS latest_price, lp.unit_symbol AS price_unit_symbol, lp.percent_change
        FROM {WatchlistItems} w
        JOIN {Products} p ON p.id = w.product_id
        JOIN {SubCategories} s ON s.id = p.sub_category_id
        JOIN {Units} u ON u.id = p.default_unit_id
        LEFT JOIN {Variants} v ON v.id = w.variant_id
        {ProductName}
        {SubCategoryName}
        {UnitName}
        {VariantName}
        LEFT JOIN LATERAL (
            SELECT r.modal_price, pu.symbol AS unit_symbol, r.record_date,
                   CASE WHEN prev_r.modal_price IS NOT NULL AND prev_r.modal_price > 0
                        THEN ROUND(CAST((r.modal_price - prev_r.modal_price) / prev_r.modal_price * 100 AS numeric), 2)
                        END AS percent_change
            FROM {PriceRecords} r
            JOIN {Units} pu ON pu.id = r.unit_id
            LEFT JOIN LATERAL (
                SELECT r2.modal_price
                FROM {PriceRecords} r2
                WHERE r2.product_id = p.id AND NOT r2.is_voided AND r2.record_date < r.record_date
                ORDER BY r2.record_date DESC
                LIMIT 1
            ) prev_r ON TRUE
            WHERE r.product_id = p.id AND NOT r.is_voided
            ORDER BY r.record_date DESC, r.created_at_utc DESC
            LIMIT 1
        ) lp ON TRUE
        WHERE w.user_id = @UserId
        ORDER BY w.created_at_utc DESC;
        """;

    public async Task<IReadOnlyList<WatchlistItemResponse>> GetWatchlistAsync(
        Guid userId,
        LanguagePreference language,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(language);

        var args = new { UserId = userId, Lang = language.Requested, DefaultLang = language.Default };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<WatchlistItemRow>(Command(WatchlistSql, args, cancellationToken));

        return rows
            .Select(r => new WatchlistItemResponse(
                r.Id,
                new ProductSummaryResponse(
                    r.ProductId,
                    r.ProductCode,
                    r.ProductName,
                    r.SubCategoryId,
                    r.SubCategoryName,
                    new UnitSummaryResponse(r.UnitId, r.UnitCode, r.UnitSymbol, r.UnitName),
                    r.ImageKey),
                r.VariantId,
                r.VariantName,
                r.CreatedAtUtc,
                r.LatestPrice,
                r.PriceUnitSymbol,
                r.PercentChange))
            .ToArray();
    }

    /// <summary>Best available name for one row: requested language, else the configured default, else English.</summary>
    private static string NameLateral(string translationTable, string ownerColumn, string ownerAlias, string alias) => $"""
        LEFT JOIN LATERAL (
            SELECT t.name
            FROM {translationTable} t
            WHERE t.{ownerColumn} = {ownerAlias}.id AND t.language_code IN (@Lang, @DefaultLang, 'en')
            ORDER BY CASE t.language_code WHEN @Lang THEN 0 WHEN @DefaultLang THEN 1 ELSE 2 END
            LIMIT 1
        ) {alias} ON TRUE
        """;

    private static CommandDefinition Command(string sql, object? args, CancellationToken cancellationToken) =>
        new(sql, args, cancellationToken: cancellationToken);

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class WatchlistItemRow
    {
        public Guid Id { get; init; }

        public Guid? VariantId { get; init; }

        public DateTimeOffset CreatedAtUtc { get; init; }

        public Guid ProductId { get; init; }

        public string ProductCode { get; init; } = string.Empty;

        public string ProductName { get; init; } = string.Empty;

        public Guid SubCategoryId { get; init; }

        public string SubCategoryName { get; init; } = string.Empty;

        public Guid UnitId { get; init; }

        public string UnitCode { get; init; } = string.Empty;

        public string UnitSymbol { get; init; } = string.Empty;

        public string UnitName { get; init; } = string.Empty;

        public string? ImageKey { get; init; }

        public string? VariantName { get; init; }

        public decimal? LatestPrice { get; init; }

        public string? PriceUnitSymbol { get; init; }

        public decimal? PercentChange { get; init; }
    }
#pragma warning restore CA1812
}
