using Dapper;
using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Alerting.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Alerting;
using MolBhav.Domain.Pricing;
using MolBhav.Infrastructure.Persistence.Configurations.Alerting;
using MolBhav.Infrastructure.Persistence.Configurations.Catalog;
using MolBhav.Infrastructure.Persistence.Configurations.Market;

namespace MolBhav.Infrastructure.Persistence.Read.Alerting;

/// <summary>Reuses catalog's language-fallback lateral-join pattern to name each rule/alert's product/variant.</summary>
internal sealed class AlertingReadService(IDbConnectionFactory connectionFactory) : IAlertingReadService
{
    private const string AlertRules = Schemas.Alerting + "." + AlertRuleConfiguration.TableName;
    private const string Alerts = Schemas.Alerting + "." + AlertConfiguration.TableName;
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

    private static readonly string ProductName = NameLateral(ProductTranslations, "product_id", "p", "pn");
    private static readonly string SubCategoryName = NameLateral(SubCategoryTranslations, "sub_category_id", "s", "sn");
    private static readonly string UnitName = NameLateral(UnitTranslations, "unit_id", "u", "un");
    private static readonly string VariantName = NameLateral(VariantTranslations, "variant_id", "v", "vn");

    private const string LocationJoins = $"""
        LEFT JOIN {Mandis} m ON m.id = x.mandi_id
        LEFT JOIN {Suppliers} sup ON sup.id = x.supplier_id
        """;

    private static readonly string AlertRulesSql = $"""
        SELECT x.id, x.variant_id, x.location_kind, x.mandi_id, x.supplier_id, x.threshold_type, x.threshold_percent,
               x.threshold_price, x.is_active, x.created_at_utc,
               p.id AS product_id, p.code AS product_code, pn.name AS product_name,
               p.sub_category_id, sn.name AS sub_category_name,
               u.id AS unit_id, u.code AS unit_code, u.symbol AS unit_symbol, un.name AS unit_name,
               p.image_key, vn.name AS variant_name,
               COALESCE(m.name, sup.name) AS location_name
        FROM {AlertRules} x
        JOIN {Products} p ON p.id = x.product_id
        JOIN {SubCategories} s ON s.id = p.sub_category_id
        JOIN {Units} u ON u.id = p.default_unit_id
        LEFT JOIN {Variants} v ON v.id = x.variant_id
        {LocationJoins}
        {ProductName}
        {SubCategoryName}
        {UnitName}
        {VariantName}
        WHERE x.user_id = @UserId
        ORDER BY x.created_at_utc DESC;
        """;

    private static readonly string AlertsSql = $"""
        SELECT count(*)
        FROM {Alerts} x
        WHERE x.user_id = @UserId;

        SELECT x.id, x.alert_rule_id, x.variant_id, x.location_kind, x.mandi_id, x.supplier_id,
               x.previous_price, x.new_price, x.percent_change, x.threshold_type, x.triggered_at_utc, x.is_read,
               p.id AS product_id, p.code AS product_code, pn.name AS product_name,
               p.sub_category_id, sn.name AS sub_category_name,
               u.id AS unit_id, u.code AS unit_code, u.symbol AS unit_symbol, un.name AS unit_name,
               p.image_key, vn.name AS variant_name,
               COALESCE(m.name, sup.name) AS location_name
        FROM {Alerts} x
        JOIN {Products} p ON p.id = x.product_id
        JOIN {SubCategories} s ON s.id = p.sub_category_id
        JOIN {Units} u ON u.id = p.default_unit_id
        LEFT JOIN {Variants} v ON v.id = x.variant_id
        {LocationJoins}
        {ProductName}
        {SubCategoryName}
        {UnitName}
        {VariantName}
        WHERE x.user_id = @UserId
        ORDER BY x.triggered_at_utc DESC
        LIMIT @Limit OFFSET @Offset;
        """;

    public async Task<IReadOnlyList<AlertRuleResponse>> GetAlertRulesAsync(Guid userId, LanguagePreference language, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(language);

        var args = new { UserId = userId, Lang = language.Requested, DefaultLang = language.Default };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<AlertRuleRow>(Command(AlertRulesSql, args, cancellationToken));

        return rows.Select(ToRuleResponse).ToArray();
    }

    public async Task<PagedResult<AlertResponse>> GetAlertsAsync(
        Guid userId,
        LanguagePreference language,
        PageRequest page,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(language);
        ArgumentNullException.ThrowIfNull(page);

        var args = new { UserId = userId, Lang = language.Requested, DefaultLang = language.Default, Limit = page.PageSize, Offset = page.Offset };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AlertsSql, args, cancellationToken));

        var totalCount = await grid.ReadSingleAsync<long>();
        var rows = await grid.ReadAsync<AlertRow>();

        return new PagedResult<AlertResponse>(rows.Select(ToAlertResponse).ToArray(), page.Page, page.PageSize, totalCount);
    }

    private static AlertRuleResponse ToRuleResponse(AlertRuleRow r) => new(
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
        r.LocationKind is null ? null : Enum.Parse<LocationKind>(r.LocationKind),
        r.MandiId,
        r.SupplierId,
        r.LocationName,
        Enum.Parse<AlertThresholdType>(r.ThresholdType),
        r.ThresholdPercent,
        r.ThresholdPrice,
        r.IsActive,
        r.CreatedAtUtc);

    private static AlertResponse ToAlertResponse(AlertRow r) => new(
        r.Id,
        r.AlertRuleId,
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
        Enum.Parse<LocationKind>(r.LocationKind),
        r.MandiId,
        r.SupplierId,
        r.LocationName,
        r.PreviousPrice,
        r.NewPrice,
        r.PercentChange,
        Enum.Parse<AlertThresholdType>(r.ThresholdType),
        r.TriggeredAtUtc,
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
    private sealed class AlertRuleRow
    {
        public Guid Id { get; init; }

        public Guid? VariantId { get; init; }

        public string? LocationKind { get; init; }

        public Guid? MandiId { get; init; }

        public Guid? SupplierId { get; init; }

        public string ThresholdType { get; init; } = string.Empty;

        public decimal? ThresholdPercent { get; init; }

        public decimal? ThresholdPrice { get; init; }

        public bool IsActive { get; init; }

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

        public string? LocationName { get; init; }
    }

    private sealed class AlertRow
    {
        public Guid Id { get; init; }

        public Guid AlertRuleId { get; init; }

        public Guid? VariantId { get; init; }

        public string LocationKind { get; init; } = string.Empty;

        public Guid? MandiId { get; init; }

        public Guid? SupplierId { get; init; }

        public decimal PreviousPrice { get; init; }

        public decimal NewPrice { get; init; }

        public decimal PercentChange { get; init; }

        public string ThresholdType { get; init; } = string.Empty;

        public DateTimeOffset TriggeredAtUtc { get; init; }

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

        public string? LocationName { get; init; }
    }
#pragma warning restore CA1812
}
