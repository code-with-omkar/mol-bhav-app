using Dapper;
using MolBhav.Infrastructure.Persistence;
using MolBhav.Infrastructure.Persistence.Configurations.Catalog;
using MolBhav.Infrastructure.Persistence.Configurations.Identity;
using MolBhav.Infrastructure.Persistence.Configurations.Market;
using MolBhav.Infrastructure.Persistence.Configurations.Pricing;
using MolBhav.Infrastructure.Persistence.Configurations.Watchlist;
using MolBhav.Infrastructure.Persistence.Read;

namespace MolBhav.Infrastructure.Reporting;

/// <summary>Report-only queries that no screen needs: watchlist movement over a period, and raw price history rows.</summary>
internal sealed class ReportDataReader(IDbConnectionFactory connectionFactory)
{
    /// <summary>Upper bound on CSV rows so one export can't exhaust memory; a year of one product nationwide fits well within it.</summary>
    public const int MaxHistoryRows = 100_000;

    private const string Users = UserConfiguration.QualifiedTableName;
    private const string WatchlistItems = Schemas.Watchlist + "." + WatchlistItemConfiguration.TableName;
    private const string Products = Schemas.Catalog + "." + ProductConfiguration.TableName;
    private const string ProductTranslations = Schemas.Catalog + "." + ProductConfiguration.TranslationsTableName;
    private const string Variants = Schemas.Catalog + "." + ProductVariantConfiguration.TableName;
    private const string VariantTranslations = Schemas.Catalog + "." + ProductVariantConfiguration.TranslationsTableName;
    private const string Units = Schemas.Catalog + "." + UnitOfMeasureConfiguration.TableName;
    private const string Mandis = Schemas.Market + "." + MandiConfiguration.TableName;
    private const string Suppliers = Schemas.Market + "." + SupplierConfiguration.TableName;
    private const string Districts = Schemas.Market + "." + DistrictConfiguration.TableName;
    private const string States = Schemas.Market + "." + StateConfiguration.TableName;
    private const string PriceSources = Schemas.Pricing + "." + PriceSourceConfiguration.TableName;
    private const string PriceRecords = Schemas.Pricing + "." + PriceRecordConfiguration.TableName;

    private const string ItemRecords = """
        r.product_id = w.product_id AND (w.variant_id IS NULL OR r.variant_id = w.variant_id)
        AND NOT r.is_voided AND r.record_date BETWEEN @FromDate AND @ToDate
        """;

    // Start/end prices average all locations on the first/last day with data, so one outlier mandi doesn't set the trend.
    private static readonly string WatchlistSql = $"""
        SELECT coalesce(pn.name, p.code) AS product_name, coalesce(vn.name, v.code) AS variant_name,
               b.first_date, b.last_date, b.low_price, b.high_price,
               f.price AS first_price, l.price AS last_price, l.unit_symbol
        FROM {WatchlistItems} w
        JOIN {Products} p ON p.id = w.product_id
        LEFT JOIN {Variants} v ON v.id = w.variant_id
        {Name(ProductTranslations, "product_id", "p", "pn")}
        {Name(VariantTranslations, "variant_id", "v", "vn")}
        LEFT JOIN LATERAL (
            SELECT min(r.record_date) AS first_date, max(r.record_date) AS last_date,
                   min(r.modal_price) AS low_price, max(r.modal_price) AS high_price
            FROM {PriceRecords} r
            WHERE {ItemRecords}
        ) b ON TRUE
        LEFT JOIN LATERAL (
            SELECT avg(r.modal_price) AS price FROM {PriceRecords} r WHERE {ItemRecords} AND r.record_date = b.first_date
        ) f ON TRUE
        LEFT JOIN LATERAL (
            SELECT avg(r.modal_price) AS price, min(u.symbol) AS unit_symbol
            FROM {PriceRecords} r JOIN {Units} u ON u.id = r.unit_id
            WHERE {ItemRecords} AND r.record_date = b.last_date
        ) l ON TRUE
        WHERE w.user_id = @UserId
        ORDER BY product_name, variant_name NULLS FIRST;
        """;

    private static readonly string PriceHistorySql = $"""
        SELECT r.record_date, coalesce(pn.name, p.code) AS product_name, coalesce(vn.name, v.code) AS variant_name,
               r.location_kind, COALESCE(m.name, sup.name) AS location_name, d.name AS district_name, st.name AS state_name,
               r.min_price, r.max_price, r.modal_price, u.symbol AS unit_symbol, r.arrival_quantity, src.name AS source_name
        FROM {PriceRecords} r
        JOIN {Products} p ON p.id = r.product_id
        LEFT JOIN {Variants} v ON v.id = r.variant_id
        LEFT JOIN {Mandis} m ON m.id = r.mandi_id
        LEFT JOIN {Suppliers} sup ON sup.id = r.supplier_id
        LEFT JOIN {Districts} d ON d.id = COALESCE(m.district_id, sup.district_id)
        LEFT JOIN {States} st ON st.id = d.state_id
        JOIN {Units} u ON u.id = r.unit_id
        JOIN {PriceSources} src ON src.id = r.price_source_id
        {Name(ProductTranslations, "product_id", "p", "pn")}
        {Name(VariantTranslations, "variant_id", "v", "vn")}
        WHERE r.product_id = @ProductId AND NOT r.is_voided
          AND r.record_date BETWEEN @FromDate AND @ToDate
          AND (@MandiId::uuid IS NULL OR r.mandi_id = @MandiId::uuid)
        ORDER BY r.record_date, state_name, district_name, location_name, variant_name NULLS FIRST
        LIMIT {MaxHistoryRows};
        """;

    private const string DisplayNameSql = $"SELECT display_name FROM {Users} WHERE id = @UserId;";

    public async Task<IReadOnlyList<WatchlistPeriodRow>> GetWatchlistPeriodAsync(
        Guid userId, DateOnly fromDate, DateOnly toDate, string language, CancellationToken cancellationToken)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<WatchlistPeriodRow>(new CommandDefinition(
            WatchlistSql,
            new { UserId = userId, FromDate = fromDate, ToDate = toDate, Lang = language, DefaultLang = "en" },
            cancellationToken: cancellationToken));
        return rows.AsList();
    }

    public async Task<IReadOnlyList<PriceHistoryRow>> GetPriceHistoryAsync(
        Guid productId, Guid? mandiId, DateOnly fromDate, DateOnly toDate, string language, CancellationToken cancellationToken)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<PriceHistoryRow>(new CommandDefinition(
            PriceHistorySql,
            new { ProductId = productId, MandiId = mandiId, FromDate = fromDate, ToDate = toDate, Lang = language, DefaultLang = "en" },
            cancellationToken: cancellationToken));
        return rows.AsList();
    }

    public async Task<string?> GetDisplayNameAsync(Guid userId, CancellationToken cancellationToken)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<string?>(
            new CommandDefinition(DisplayNameSql, new { UserId = userId }, cancellationToken: cancellationToken));
    }

    private static string Name(string translationTable, string ownerColumn, string ownerAlias, string alias) => $"""
        LEFT JOIN LATERAL (
            SELECT t.name
            FROM {translationTable} t
            WHERE t.{ownerColumn} = {ownerAlias}.id AND t.language_code IN (@Lang, @DefaultLang)
            ORDER BY CASE t.language_code WHEN @Lang THEN 0 ELSE 1 END
            LIMIT 1
        ) {alias} ON TRUE
        """;
}

internal sealed class WatchlistPeriodRow
{
    public string ProductName { get; init; } = string.Empty;

    public string? VariantName { get; init; }

    public DateOnly? FirstDate { get; init; }

    public DateOnly? LastDate { get; init; }

    public decimal? LowPrice { get; init; }

    public decimal? HighPrice { get; init; }

    public decimal? FirstPrice { get; init; }

    public decimal? LastPrice { get; init; }

    public string? UnitSymbol { get; init; }

    /// <summary>Change from the first to the last day with data in the period; null with fewer than two such days.</summary>
    public decimal? PercentChange =>
        FirstPrice is > 0 && LastPrice is { } last && FirstDate != LastDate
            ? Math.Round((last - FirstPrice.Value) / FirstPrice.Value * 100, 1)
            : null;
}

internal sealed class PriceHistoryRow
{
    public DateOnly RecordDate { get; init; }

    public string ProductName { get; init; } = string.Empty;

    public string? VariantName { get; init; }

    public string LocationKind { get; init; } = string.Empty;

    public string? LocationName { get; init; }

    public string? DistrictName { get; init; }

    public string? StateName { get; init; }

    public decimal? MinPrice { get; init; }

    public decimal? MaxPrice { get; init; }

    public decimal ModalPrice { get; init; }

    public string UnitSymbol { get; init; } = string.Empty;

    public decimal? ArrivalQuantity { get; init; }

    public string SourceName { get; init; } = string.Empty;
}
