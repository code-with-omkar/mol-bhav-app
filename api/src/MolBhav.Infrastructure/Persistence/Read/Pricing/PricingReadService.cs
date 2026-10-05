using Dapper;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Pricing;
using MolBhav.Infrastructure.Persistence.Configurations.Catalog;
using MolBhav.Infrastructure.Persistence.Configurations.Market;
using MolBhav.Infrastructure.Persistence.Configurations.Pricing;

namespace MolBhav.Infrastructure.Persistence.Read.Pricing;

/// <summary>
/// Pricing reads for the mobile comparison/trend screens and the admin portal. Location (mandi vs. supplier) is
/// resolved with a pair of LEFT JOINs picked by <c>location_kind</c>, mirroring the two-nullable-FK model on
/// <see cref="PriceRecord"/>.
/// </summary>
internal sealed class PricingReadService(IDbConnectionFactory connectionFactory) : IPricingReadService
{
    private const string Products = Schemas.Catalog + "." + ProductConfiguration.TableName;
    private const string ProductTranslations = Schemas.Catalog + "." + ProductConfiguration.TranslationsTableName;
    private const string Variants = Schemas.Catalog + "." + ProductVariantConfiguration.TableName;
    private const string Units = Schemas.Catalog + "." + UnitOfMeasureConfiguration.TableName;
    private const string UnitTranslations = Schemas.Catalog + "." + UnitOfMeasureConfiguration.TranslationsTableName;
    private const string Mandis = Schemas.Market + "." + MandiConfiguration.TableName;
    private const string Suppliers = Schemas.Market + "." + SupplierConfiguration.TableName;
    private const string Districts = Schemas.Market + "." + DistrictConfiguration.TableName;
    private const string States = Schemas.Market + "." + StateConfiguration.TableName;
    private const string Categories = Schemas.Catalog + "." + ProcurementCategoryConfiguration.TableName;
    private const string PriceSources = Schemas.Pricing + "." + PriceSourceConfiguration.TableName;
    private const string PriceRecords = Schemas.Pricing + "." + PriceRecordConfiguration.TableName;

    private const string LocationJoins = $"""
        LEFT JOIN {Mandis} m ON m.id = r.mandi_id
        LEFT JOIN {Suppliers} sup ON sup.id = r.supplier_id
        LEFT JOIN {Districts} d ON d.id = COALESCE(m.district_id, sup.district_id)
        LEFT JOIN {States} st ON st.id = d.state_id
        """;

    // A WITH clause only scopes the single statement that follows it, so the CTE is repeated for both the
    // count and the data query rather than shared across the semicolon-separated Dapper batch.
    private const string LatestRecordsCte = $"""
        WITH latest AS (
            SELECT DISTINCT ON (COALESCE(r.mandi_id, r.supplier_id))
                r.mandi_id, r.supplier_id, r.min_price, r.max_price, r.modal_price,
                r.unit_id, r.arrival_quantity, r.record_date, r.price_source_id
            FROM {PriceRecords} r
            WHERE r.product_id = @ProductId AND NOT r.is_voided
              AND (@LocationKind::text IS NULL OR r.location_kind = @LocationKind::text)
            ORDER BY COALESCE(r.mandi_id, r.supplier_id), r.record_date DESC
        )
        """;

    private static readonly string LatestPricesSql = $"""
        {LatestRecordsCte}
        SELECT count(*)
        FROM latest r
        {LocationJoins}
        WHERE (@DistrictId::uuid IS NULL OR d.id = @DistrictId::uuid);

        {LatestRecordsCte}
        SELECT
            CASE WHEN r.mandi_id IS NOT NULL THEN 'Mandi' ELSE 'Supplier' END AS location_kind,
            COALESCE(m.id, sup.id) AS location_id,
            COALESCE(m.name, sup.name) AS location_name,
            d.name AS district_name,
            st.name AS state_name,
            r.min_price, r.max_price, r.modal_price,
            u.code AS unit_code, u.symbol AS unit_symbol,
            r.arrival_quantity, r.record_date,
            src.name AS source_name
        FROM latest r
        {LocationJoins}
        JOIN {Units} u ON u.id = r.unit_id
        JOIN {PriceSources} src ON src.id = r.price_source_id
        WHERE (@DistrictId::uuid IS NULL OR d.id = @DistrictId::uuid)
        ORDER BY st.name, d.name, location_name
        LIMIT @Limit OFFSET @Offset;
        """;

    private const string VariantTranslations = Schemas.Catalog + "." + ProductVariantConfiguration.TranslationsTableName;

    private static readonly string LatestByMandiSql = LatestByLocationSql("mandi_id");
    private static readonly string LatestBySupplierSql = LatestByLocationSql("supplier_id");

    // Served by the partial (mandi_id|supplier_id, record_date DESC) WHERE NOT is_voided indexes: one range scan
    // over the location's recent records, then DISTINCT ON keeps the newest per product/variant.
    private static string LatestByLocationSql(string locationColumn)
    {
        var cte = $"""
            WITH latest AS (
                SELECT DISTINCT ON (r.product_id, r.variant_id)
                    r.product_id, r.variant_id, r.min_price, r.max_price, r.modal_price,
                    r.unit_id, r.arrival_quantity, r.record_date, r.price_source_id
                FROM {PriceRecords} r
                WHERE r.{locationColumn} = @LocationId AND NOT r.is_voided AND r.record_date >= @SinceDate
                ORDER BY r.product_id, r.variant_id, r.record_date DESC
            )
            """;

        return $"""
            {cte}
            SELECT count(*) FROM latest r JOIN {Products} p ON p.id = r.product_id AND p.is_active;

            {cte}
            SELECT r.product_id, coalesce(pn.name, p.code) AS product_name,
                   r.variant_id, coalesce(vn.name, v.code) AS variant_name,
                   r.min_price, r.max_price, r.modal_price,
                   u.code AS unit_code, u.symbol AS unit_symbol,
                   r.arrival_quantity, r.record_date, src.name AS source_name
            FROM latest r
            JOIN {Products} p ON p.id = r.product_id AND p.is_active
            LEFT JOIN {Variants} v ON v.id = r.variant_id
            JOIN {Units} u ON u.id = r.unit_id
            JOIN {PriceSources} src ON src.id = r.price_source_id
            {TranslatedName(ProductTranslations, "product_id", "p", "pn")}
            {TranslatedName(VariantTranslations, "variant_id", "v", "vn")}
            ORDER BY product_name, variant_name NULLS FIRST
            LIMIT @Limit OFFSET @Offset;
            """;
    }

    private static string TranslatedName(string translationTable, string ownerColumn, string ownerAlias, string alias) => $"""
        LEFT JOIN LATERAL (
            SELECT t.name
            FROM {translationTable} t
            WHERE t.{ownerColumn} = {ownerAlias}.id AND t.language_code IN (@Lang, @DefaultLang, 'en')
            ORDER BY CASE t.language_code WHEN @Lang THEN 0 WHEN @DefaultLang THEN 1 ELSE 2 END
            LIMIT 1
        ) {alias} ON TRUE
        """;

    private const string PriceHistorySql = $"""
        SELECT r.record_date, r.min_price, r.max_price, r.modal_price
        FROM {PriceRecords} r
        WHERE r.product_id = @ProductId
          AND r.location_kind = @LocationKind::text
          AND (r.mandi_id = @LocationId OR r.supplier_id = @LocationId)
          AND NOT r.is_voided
          AND r.record_date BETWEEN @FromDate AND @ToDate
        ORDER BY r.record_date;
        """;

    private const string AdminPriceSourcesSql = $"""
        SELECT s.id, s.code, s.name, s.is_active, c.code AS category_code
        FROM {PriceSources} s
        JOIN {Categories} c ON c.id = s.category_id
        ORDER BY c.display_order, s.name;
        """;

    private const string AdminPriceRecordListFrom = $"""
        FROM {PriceRecords} r
        JOIN {Products} p ON p.id = r.product_id
        LEFT JOIN {Variants} v ON v.id = r.variant_id
        JOIN {Units} u ON u.id = r.unit_id
        JOIN {PriceSources} src ON src.id = r.price_source_id
        {LocationJoins}
        """;

    private const string AdminPriceRecordListWhere = $"""
        WHERE (@ProductId::uuid IS NULL OR r.product_id = @ProductId::uuid)
          AND (@LocationKind::text IS NULL OR r.location_kind = @LocationKind::text)
          AND (@LocationId::uuid IS NULL OR r.mandi_id = @LocationId::uuid OR r.supplier_id = @LocationId::uuid)
          AND (@FromDate::date IS NULL OR r.record_date >= @FromDate::date)
          AND (@ToDate::date IS NULL OR r.record_date <= @ToDate::date)
          AND (@IsVoided::boolean IS NULL OR r.is_voided = @IsVoided::boolean)
        """;

    private static readonly string AdminPriceRecordListSql = $"""
        SELECT count(*)
        {AdminPriceRecordListFrom}
        {AdminPriceRecordListWhere};

        SELECT r.id, r.product_id, p.code AS product_code, r.variant_id, v.code AS variant_code,
               CASE WHEN r.mandi_id IS NOT NULL THEN 'Mandi' ELSE 'Supplier' END AS location_kind,
               COALESCE(m.id, sup.id) AS location_id, COALESCE(m.name, sup.name) AS location_name,
               r.unit_id, u.code AS unit_code, r.min_price, r.max_price, r.modal_price, r.arrival_quantity,
               r.record_date, r.price_source_id, src.code AS source_code, r.is_voided
        {AdminPriceRecordListFrom}
        {AdminPriceRecordListWhere}
        ORDER BY r.record_date DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    public async Task<PagedResult<LatestPriceResponse>> GetLatestPricesAsync(LatestPriceFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("ProductId", filter.ProductId);
        args.Add("LocationKind", filter.LocationKind?.ToString());
        args.Add("DistrictId", filter.DistrictId);
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(LatestPricesSql, args, cancellationToken));

        var total = await grid.ReadSingleAsync<long>();
        var items = (await grid.ReadAsync<LatestPriceRow>())
            .Select(r => new LatestPriceResponse(
                Enum.Parse<LocationKind>(r.LocationKind),
                r.LocationId,
                r.LocationName,
                r.DistrictName,
                r.StateName,
                r.MinPrice,
                r.MaxPrice,
                r.ModalPrice,
                r.UnitCode,
                r.UnitSymbol,
                r.ArrivalQuantity,
                r.RecordDate,
                r.SourceName))
            .ToArray();

        return new PagedResult<LatestPriceResponse>(items, filter.Page.Page, filter.Page.PageSize, total);
    }

    public async Task<PagedResult<LocationLatestPriceResponse>> GetLatestByLocationAsync(LatestByLocationFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("LocationId", filter.LocationId);
        args.Add("SinceDate", filter.SinceDate);
        args.Add("Lang", filter.Language.Requested);
        args.Add("DefaultLang", filter.Language.Default);
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        var sql = filter.LocationKind == LocationKind.Mandi ? LatestByMandiSql : LatestBySupplierSql;

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(sql, args, cancellationToken));

        var total = await grid.ReadSingleAsync<long>();
        var items = (await grid.ReadAsync<LocationLatestPriceRow>())
            .Select(r => new LocationLatestPriceResponse(
                r.ProductId,
                r.ProductName,
                r.VariantId,
                r.VariantName,
                r.MinPrice,
                r.MaxPrice,
                r.ModalPrice,
                r.UnitCode,
                r.UnitSymbol,
                r.ArrivalQuantity,
                r.RecordDate,
                r.SourceName))
            .ToArray();

        return new PagedResult<LocationLatestPriceResponse>(items, filter.Page.Page, filter.Page.PageSize, total);
    }

    public async Task<IReadOnlyList<PriceHistoryPointResponse>> GetPriceHistoryAsync(PriceHistoryFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new
        {
            filter.ProductId,
            LocationKind = filter.LocationKind.ToString(),
            filter.LocationId,
            filter.FromDate,
            filter.ToDate,
        };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<PriceHistoryRow>(Command(PriceHistorySql, args, cancellationToken));

        return rows.Select(r => new PriceHistoryPointResponse(r.RecordDate, r.MinPrice, r.MaxPrice, r.ModalPrice)).ToArray();
    }

    public async Task<IReadOnlyList<AdminPriceSourceResponse>> GetAdminPriceSourcesAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<AdminPriceSourceRow>(Command(AdminPriceSourcesSql, null, cancellationToken));
        return rows.Select(s => new AdminPriceSourceResponse(s.Id, s.Code, s.Name, s.IsActive, s.CategoryCode)).ToArray();
    }

    public async Task<PagedResult<AdminPriceRecordResponse>> GetAdminPriceRecordsAsync(AdminPriceRecordFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("ProductId", filter.ProductId);
        args.Add("LocationKind", filter.LocationKind?.ToString());
        args.Add("LocationId", filter.LocationId);
        args.Add("FromDate", filter.FromDate);
        args.Add("ToDate", filter.ToDate);
        args.Add("IsVoided", filter.IsVoided);
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminPriceRecordListSql, args, cancellationToken));

        var total = await grid.ReadSingleAsync<long>();
        var items = (await grid.ReadAsync<AdminPriceRecordRow>())
            .Select(r => new AdminPriceRecordResponse(
                r.Id, r.ProductId, r.ProductCode, r.VariantId, r.VariantCode,
                Enum.Parse<LocationKind>(r.LocationKind), r.LocationId, r.LocationName,
                r.UnitId, r.UnitCode, r.MinPrice, r.MaxPrice, r.ModalPrice, r.ArrivalQuantity,
                r.RecordDate, r.PriceSourceId, r.SourceCode, r.IsVoided))
            .ToArray();

        return new PagedResult<AdminPriceRecordResponse>(items, filter.Page.Page, filter.Page.PageSize, total);
    }

    private static CommandDefinition Command(string sql, object? args, CancellationToken cancellationToken) =>
        new(sql, args, cancellationToken: cancellationToken);

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class LatestPriceRow
    {
        public string LocationKind { get; init; } = string.Empty;

        public Guid LocationId { get; init; }

        public string LocationName { get; init; } = string.Empty;

        public string DistrictName { get; init; } = string.Empty;

        public string StateName { get; init; } = string.Empty;

        public decimal? MinPrice { get; init; }

        public decimal? MaxPrice { get; init; }

        public decimal ModalPrice { get; init; }

        public string UnitCode { get; init; } = string.Empty;

        public string UnitSymbol { get; init; } = string.Empty;

        public decimal? ArrivalQuantity { get; init; }

        public DateOnly RecordDate { get; init; }

        public string SourceName { get; init; } = string.Empty;
    }

    private sealed class LocationLatestPriceRow
    {
        public Guid ProductId { get; init; }

        public string ProductName { get; init; } = string.Empty;

        public Guid? VariantId { get; init; }

        public string? VariantName { get; init; }

        public decimal? MinPrice { get; init; }

        public decimal? MaxPrice { get; init; }

        public decimal ModalPrice { get; init; }

        public string UnitCode { get; init; } = string.Empty;

        public string UnitSymbol { get; init; } = string.Empty;

        public decimal? ArrivalQuantity { get; init; }

        public DateOnly RecordDate { get; init; }

        public string SourceName { get; init; } = string.Empty;
    }

    private sealed class PriceHistoryRow
    {
        public DateOnly RecordDate { get; init; }

        public decimal? MinPrice { get; init; }

        public decimal? MaxPrice { get; init; }

        public decimal ModalPrice { get; init; }
    }

    private sealed class AdminPriceSourceRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public bool IsActive { get; init; }

        public string CategoryCode { get; init; } = string.Empty;
    }

    private sealed class AdminPriceRecordRow
    {
        public Guid Id { get; init; }

        public Guid ProductId { get; init; }

        public string ProductCode { get; init; } = string.Empty;

        public Guid? VariantId { get; init; }

        public string? VariantCode { get; init; }

        public string LocationKind { get; init; } = string.Empty;

        public Guid LocationId { get; init; }

        public string LocationName { get; init; } = string.Empty;

        public Guid UnitId { get; init; }

        public string UnitCode { get; init; } = string.Empty;

        public decimal? MinPrice { get; init; }

        public decimal? MaxPrice { get; init; }

        public decimal ModalPrice { get; init; }

        public decimal? ArrivalQuantity { get; init; }

        public DateOnly RecordDate { get; init; }

        public Guid PriceSourceId { get; init; }

        public string SourceCode { get; init; } = string.Empty;

        public bool IsVoided { get; init; }
    }
#pragma warning restore CA1812
}
