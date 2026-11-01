using Dapper;
using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Alerting.Opportunities.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Pricing;
using MolBhav.Infrastructure.Persistence.Configurations.Alerting;
using MolBhav.Infrastructure.Persistence.Configurations.Catalog;
using MolBhav.Infrastructure.Persistence.Configurations.Identity;
using MolBhav.Infrastructure.Persistence.Configurations.Market;
using MolBhav.Infrastructure.Persistence.Configurations.Pricing;
using MolBhav.Infrastructure.Persistence.Configurations.Watchlist;

namespace MolBhav.Infrastructure.Persistence.Read.Alerting;

/// <summary>
/// Opportunity scan inputs and the opportunity screens. "Newest price per market" uses the same DISTINCT ON pattern as
/// the comparison matrix, but keyed by variant too so two varieties are never compared with each other.
/// </summary>
internal sealed class MarketOpportunityReadService(IDbConnectionFactory connectionFactory) : IMarketOpportunityReadService
{
    private const string Opportunities = Schemas.Alerting + "." + MarketOpportunityConfiguration.TableName;
    private const string Watchlist = Schemas.Watchlist + "." + WatchlistItemConfiguration.TableName;
    private const string PriceRecords = Schemas.Pricing + "." + PriceRecordConfiguration.TableName;
    private const string Products = Schemas.Catalog + "." + ProductConfiguration.TableName;
    private const string ProductTranslations = Schemas.Catalog + "." + ProductConfiguration.TranslationsTableName;
    private const string Variants = Schemas.Catalog + "." + ProductVariantConfiguration.TableName;
    private const string VariantTranslations = Schemas.Catalog + "." + ProductVariantConfiguration.TranslationsTableName;
    private const string SubCategories = Schemas.Catalog + "." + SubCategoryConfiguration.TableName;
    private const string SubCategoryTranslations = Schemas.Catalog + "." + SubCategoryConfiguration.TranslationsTableName;
    private const string Units = Schemas.Catalog + "." + UnitOfMeasureConfiguration.TableName;
    private const string UnitTranslations = Schemas.Catalog + "." + UnitOfMeasureConfiguration.TranslationsTableName;
    private const string Mandis = Schemas.Market + "." + MandiConfiguration.TableName;
    private const string Suppliers = Schemas.Market + "." + SupplierConfiguration.TableName;
    private const string Districts = Schemas.Market + "." + DistrictConfiguration.TableName;
    private const string States = Schemas.Market + "." + StateConfiguration.TableName;

    // Profile state/district are stored as the picker's keys (state code, district name); older rows may hold the
    // state name — resolved the same way as the profile read.
    private const string WatchersSql = $"""
        SELECT w.user_id, w.product_id, w.variant_id, d.id AS home_district_id
        FROM {Watchlist} w
        JOIN {UserConfiguration.QualifiedTableName} u ON u.id = w.user_id
        JOIN LATERAL (
            SELECT st.id
            FROM {States} st
            WHERE upper(st.code) = upper(u.state) OR lower(st.name) = lower(u.state)
            ORDER BY (upper(st.code) = upper(u.state)) DESC
            LIMIT 1
        ) s ON TRUE
        JOIN LATERAL (
            SELECT dt.id
            FROM {Districts} dt
            WHERE dt.state_id = s.id AND lower(dt.name) = lower(u.district)
            LIMIT 1
        ) d ON TRUE;
        """;

    private const string LatestPricesSql = $"""
        SELECT DISTINCT ON (r.product_id, r.variant_id, COALESCE(r.mandi_id, r.supplier_id))
               r.product_id, r.variant_id, r.location_kind, r.mandi_id, r.supplier_id,
               COALESCE(m.district_id, sup.district_id) AS district_id, r.modal_price, r.record_date
        FROM {PriceRecords} r
        LEFT JOIN {Mandis} m ON m.id = r.mandi_id AND m.is_active
        LEFT JOIN {Suppliers} sup ON sup.id = r.supplier_id AND sup.is_active
        WHERE r.product_id = ANY(@ProductIds) AND NOT r.is_voided AND r.record_date >= @Since
          AND COALESCE(m.district_id, sup.district_id) IS NOT NULL
        ORDER BY r.product_id, r.variant_id, COALESCE(r.mandi_id, r.supplier_id), r.record_date DESC;
        """;

    private const string MarketPricesSql = $"""
        SELECT DISTINCT ON (COALESCE(r.mandi_id, r.supplier_id))
               r.location_kind, COALESCE(r.mandi_id, r.supplier_id) AS location_id,
               COALESCE(m.name, sup.name) AS name, d.id AS district_id, d.name AS district_name,
               r.modal_price, r.record_date
        FROM {PriceRecords} r
        LEFT JOIN {Mandis} m ON m.id = r.mandi_id AND m.is_active
        LEFT JOIN {Suppliers} sup ON sup.id = r.supplier_id AND sup.is_active
        JOIN {Districts} d ON d.id = COALESCE(m.district_id, sup.district_id)
        WHERE r.product_id = @ProductId AND r.variant_id IS NOT DISTINCT FROM @VariantId::uuid
          AND NOT r.is_voided AND r.record_date >= @Since
        ORDER BY COALESCE(r.mandi_id, r.supplier_id), r.record_date DESC;
        """;

    private static readonly string ProductName = NameLateral(ProductTranslations, "product_id", "p", "pn");
    private static readonly string SubCategoryName = NameLateral(SubCategoryTranslations, "sub_category_id", "s", "sn");
    private static readonly string UnitName = NameLateral(UnitTranslations, "unit_id", "u", "un");
    private static readonly string VariantName = NameLateral(VariantTranslations, "variant_id", "v", "vn");

    private static readonly string OpportunitySelect = $"""
        SELECT x.id, x.variant_id,
               x.home_location_kind, COALESCE(x.home_mandi_id, x.home_supplier_id) AS home_location_id,
               COALESCE(hm.name, hs.name) AS home_name, hd.name AS home_district_name, x.home_price,
               x.best_location_kind, COALESCE(x.best_mandi_id, x.best_supplier_id) AS best_location_id,
               COALESCE(bm.name, bs.name) AS best_name, bd.name AS best_district_name, x.best_price,
               x.landed_price, x.savings_percent, x.price_date, x.detected_on, x.detected_at_utc, x.is_read,
               p.id AS product_id, p.code AS product_code, pn.name AS product_name,
               p.sub_category_id, sn.name AS sub_category_name,
               u.id AS unit_id, u.code AS unit_code, u.symbol AS unit_symbol, un.name AS unit_name,
               p.image_key, vn.name AS variant_name
        FROM {Opportunities} x
        JOIN {Products} p ON p.id = x.product_id
        JOIN {SubCategories} s ON s.id = p.sub_category_id
        JOIN {Units} u ON u.id = p.default_unit_id
        LEFT JOIN {Variants} v ON v.id = x.variant_id
        LEFT JOIN {Mandis} hm ON hm.id = x.home_mandi_id
        LEFT JOIN {Suppliers} hs ON hs.id = x.home_supplier_id
        LEFT JOIN {Districts} hd ON hd.id = COALESCE(hm.district_id, hs.district_id)
        LEFT JOIN {Mandis} bm ON bm.id = x.best_mandi_id
        LEFT JOIN {Suppliers} bs ON bs.id = x.best_supplier_id
        LEFT JOIN {Districts} bd ON bd.id = COALESCE(bm.district_id, bs.district_id)
        {ProductName}
        {SubCategoryName}
        {UnitName}
        {VariantName}
        """;

    private static readonly string OpportunitiesSql = $"""
        SELECT count(*) FROM {Opportunities} x WHERE x.user_id = @UserId;

        {OpportunitySelect}
        WHERE x.user_id = @UserId
        ORDER BY x.detected_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    private static readonly string OpportunitySql = $"""
        {OpportunitySelect}
        WHERE x.user_id = @UserId AND x.id = @Id;
        """;

    public async Task<IReadOnlyList<OpportunityWatcher>> GetWatchersAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<WatcherRow>(Command(WatchersSql, null, cancellationToken));
        return rows.Select(r => new OpportunityWatcher(r.UserId, r.ProductId, r.VariantId, r.HomeDistrictId)).ToArray();
    }

    public async Task<IReadOnlyList<OpportunityPrice>> GetLatestPricesAsync(
        IReadOnlyCollection<Guid> productIds,
        DateOnly since,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(productIds);
        if (productIds.Count == 0)
        {
            return [];
        }

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<PriceRow>(Command(
            LatestPricesSql, new { ProductIds = productIds.ToArray(), Since = since }, cancellationToken));

        return rows.Select(r => new OpportunityPrice(
                r.ProductId,
                r.VariantId,
                Enum.Parse<LocationKind>(r.LocationKind),
                r.MandiId,
                r.SupplierId,
                r.DistrictId,
                r.ModalPrice,
                r.RecordDate))
            .ToArray();
    }

    public async Task<PagedResult<MarketOpportunityResponse>> GetOpportunitiesAsync(
        Guid userId,
        LanguagePreference language,
        PageRequest page,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(language);
        ArgumentNullException.ThrowIfNull(page);

        var args = new
        {
            UserId = userId,
            Lang = language.Requested,
            DefaultLang = language.Default,
            Limit = page.PageSize,
            Offset = page.Offset,
        };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(OpportunitiesSql, args, cancellationToken));

        var total = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<OpportunityRow>();

        return new PagedResult<MarketOpportunityResponse>(rows.Select(ToResponse).ToArray(), page.Page, page.PageSize, total);
    }

    public async Task<MarketOpportunityResponse?> GetOpportunityAsync(
        Guid userId,
        Guid opportunityId,
        LanguagePreference language,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(language);

        var args = new { UserId = userId, Id = opportunityId, Lang = language.Requested, DefaultLang = language.Default };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var row = await connection.QuerySingleOrDefaultAsync<OpportunityRow>(Command(OpportunitySql, args, cancellationToken));
        return row is null ? null : ToResponse(row);
    }

    public async Task<IReadOnlyList<OpportunityMarketRow>> GetMarketPricesAsync(
        Guid productId,
        Guid? variantId,
        DateOnly since,
        CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<MarketRow>(Command(
            MarketPricesSql, new { ProductId = productId, VariantId = variantId, Since = since }, cancellationToken));

        return rows.Select(r => new OpportunityMarketRow(
                Enum.Parse<LocationKind>(r.LocationKind),
                r.LocationId,
                r.Name,
                r.DistrictId,
                r.DistrictName,
                r.ModalPrice,
                r.RecordDate))
            .ToArray();
    }

    private static MarketOpportunityResponse ToResponse(OpportunityRow r) => new(
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
        new OpportunityMarketResponse(
            Enum.Parse<LocationKind>(r.HomeLocationKind), r.HomeLocationId, r.HomeName ?? string.Empty, r.HomeDistrictName ?? string.Empty, r.HomePrice),
        new OpportunityMarketResponse(
            Enum.Parse<LocationKind>(r.BestLocationKind), r.BestLocationId, r.BestName ?? string.Empty, r.BestDistrictName ?? string.Empty, r.BestPrice),
        r.LandedPrice,
        r.SavingsPercent,
        r.HomePrice - r.LandedPrice,
        r.PriceDate,
        r.DetectedOn,
        r.DetectedAtUtc,
        r.IsRead);

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
    private sealed class WatcherRow
    {
        public Guid UserId { get; init; }

        public Guid ProductId { get; init; }

        public Guid? VariantId { get; init; }

        public Guid HomeDistrictId { get; init; }
    }

    private sealed class PriceRow
    {
        public Guid ProductId { get; init; }

        public Guid? VariantId { get; init; }

        public string LocationKind { get; init; } = string.Empty;

        public Guid? MandiId { get; init; }

        public Guid? SupplierId { get; init; }

        public Guid DistrictId { get; init; }

        public decimal ModalPrice { get; init; }

        public DateOnly RecordDate { get; init; }
    }

    private sealed class MarketRow
    {
        public string LocationKind { get; init; } = string.Empty;

        public Guid LocationId { get; init; }

        public string Name { get; init; } = string.Empty;

        public Guid DistrictId { get; init; }

        public string DistrictName { get; init; } = string.Empty;

        public decimal ModalPrice { get; init; }

        public DateOnly RecordDate { get; init; }
    }

    private sealed class OpportunityRow
    {
        public Guid Id { get; init; }

        public Guid? VariantId { get; init; }

        public string HomeLocationKind { get; init; } = string.Empty;

        public Guid HomeLocationId { get; init; }

        public string? HomeName { get; init; }

        public string? HomeDistrictName { get; init; }

        public decimal HomePrice { get; init; }

        public string BestLocationKind { get; init; } = string.Empty;

        public Guid BestLocationId { get; init; }

        public string? BestName { get; init; }

        public string? BestDistrictName { get; init; }

        public decimal BestPrice { get; init; }

        public decimal LandedPrice { get; init; }

        public decimal SavingsPercent { get; init; }

        public DateOnly PriceDate { get; init; }

        public DateOnly DetectedOn { get; init; }

        public DateTimeOffset DetectedAtUtc { get; init; }

        public bool IsRead { get; init; }

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
    }
#pragma warning restore CA1812
}
