using Dapper;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Procurement.Models;
using MolBhav.Domain.Pricing;
using MolBhav.Infrastructure.Persistence.Configurations.Catalog;
using MolBhav.Infrastructure.Persistence.Configurations.Market;
using MolBhav.Infrastructure.Persistence.Configurations.Procurement;

namespace MolBhav.Infrastructure.Persistence.Read.Procurement;

/// <summary>Reuses catalog's language-fallback lateral-join pattern to name each requirement's product/variant.</summary>
internal sealed class ProcurementReadService(IDbConnectionFactory connectionFactory) : IProcurementReadService
{
    private const string Requirements = Schemas.Procurement + "." + ProcurementRequirementConfiguration.TableName;
    private const string Opportunities = Schemas.Procurement + "." + ProcurementOpportunityConfiguration.TableName;
    private const string CostComponents = Schemas.Procurement + "." + CostComponentConfiguration.TableName;
    private const string Products = Schemas.Catalog + "." + ProductConfiguration.TableName;
    private const string ProductTranslations = Schemas.Catalog + "." + ProductConfiguration.TranslationsTableName;
    private const string Variants = Schemas.Catalog + "." + ProductVariantConfiguration.TableName;
    private const string VariantTranslations = Schemas.Catalog + "." + ProductVariantConfiguration.TranslationsTableName;
    private const string SubCategories = Schemas.Catalog + "." + SubCategoryConfiguration.TableName;
    private const string SubCategoryTranslations = Schemas.Catalog + "." + SubCategoryConfiguration.TranslationsTableName;
    private const string Units = Schemas.Catalog + "." + UnitOfMeasureConfiguration.TableName;
    private const string UnitTranslations = Schemas.Catalog + "." + UnitOfMeasureConfiguration.TranslationsTableName;
    private const string Districts = Schemas.Market + "." + DistrictConfiguration.TableName;

    private static readonly string ProductName = NameLateral(ProductTranslations, "product_id", "p", "pn");
    private static readonly string SubCategoryName = NameLateral(SubCategoryTranslations, "sub_category_id", "s", "sn");
    private static readonly string UnitName = NameLateral(UnitTranslations, "unit_id", "u", "un");
    private static readonly string VariantName = NameLateral(VariantTranslations, "variant_id", "v", "vn");

    private static readonly string RequirementsSql = $"""
        SELECT r.id, r.variant_id, r.quantity, r.target_district_id, d.name AS target_district_name,
               r.target_price, r.created_at_utc,
               p.id AS product_id, p.code AS product_code, pn.name AS product_name,
               p.sub_category_id, sn.name AS sub_category_name,
               u.id AS unit_id, u.code AS unit_code, u.symbol AS unit_symbol, un.name AS unit_name,
               p.image_key, vn.name AS variant_name
        FROM {Requirements} r
        JOIN {Products} p ON p.id = r.product_id
        JOIN {SubCategories} s ON s.id = p.sub_category_id
        JOIN {Units} u ON u.id = r.unit_id
        LEFT JOIN {Variants} v ON v.id = r.variant_id
        LEFT JOIN {Districts} d ON d.id = r.target_district_id
        {ProductName}
        {SubCategoryName}
        {UnitName}
        {VariantName}
        WHERE r.user_id = @UserId
        ORDER BY r.created_at_utc DESC;
        """;

    private const string OpportunitiesSql = $"""
        SELECT o.id, o.location_kind, o.location_id, o.location_name,
               o.quantity, o.unit_price, o.estimated_cost, o.savings_vs_target, o.price_record_date, o.computed_at_utc
        FROM {Opportunities} o
        JOIN {Requirements} r ON r.id = o.requirement_id
        WHERE o.requirement_id = @RequirementId AND r.user_id = @UserId
        ORDER BY o.estimated_cost;
        """;

    private const string AdminCostComponentsSql = $"""
        SELECT c.id, c.code, c.name, c.component_type, c.value, c.is_active
        FROM {CostComponents} c
        ORDER BY c.name;
        """;

    public async Task<IReadOnlyList<ProcurementRequirementResponse>> GetMyRequirementsAsync(
        Guid userId, LanguagePreference language, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(language);

        var args = new { UserId = userId, Lang = language.Requested, DefaultLang = language.Default };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<RequirementRow>(Command(RequirementsSql, args, cancellationToken));

        return rows
            .Select(r => new ProcurementRequirementResponse(
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
                r.Quantity,
                new UnitSummaryResponse(r.UnitId, r.UnitCode, r.UnitSymbol, r.UnitName),
                r.TargetDistrictId,
                r.TargetDistrictName,
                r.TargetPrice,
                r.CreatedAtUtc))
            .ToArray();
    }

    public async Task<IReadOnlyList<ProcurementOpportunityResponse>> GetOpportunitiesAsync(
        Guid requirementId, Guid userId, CancellationToken cancellationToken = default)
    {
        var args = new { RequirementId = requirementId, UserId = userId };

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<OpportunityRow>(Command(OpportunitiesSql, args, cancellationToken));

        return rows
            .Select(o => new ProcurementOpportunityResponse(
                o.Id,
                Enum.Parse<LocationKind>(o.LocationKind),
                o.LocationId,
                o.LocationName,
                o.Quantity,
                o.UnitPrice,
                o.EstimatedCost,
                o.SavingsVsTarget,
                o.PriceRecordDate,
                o.ComputedAtUtc))
            .ToArray();
    }

    public async Task<IReadOnlyList<AdminCostComponentResponse>> GetAdminCostComponentsAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<AdminCostComponentRow>(Command(AdminCostComponentsSql, null, cancellationToken));

        return rows
            .Select(c => new AdminCostComponentResponse(c.Id, c.Code, c.Name, Enum.Parse<Domain.Procurement.CostComponentType>(c.ComponentType), c.Value, c.IsActive))
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
    private sealed class RequirementRow
    {
        public Guid Id { get; init; }

        public Guid? VariantId { get; init; }

        public decimal Quantity { get; init; }

        public Guid? TargetDistrictId { get; init; }

        public string? TargetDistrictName { get; init; }

        public decimal? TargetPrice { get; init; }

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
    }

    private sealed class OpportunityRow
    {
        public Guid Id { get; init; }

        public string LocationKind { get; init; } = string.Empty;

        public Guid LocationId { get; init; }

        public string LocationName { get; init; } = string.Empty;

        public decimal Quantity { get; init; }

        public decimal UnitPrice { get; init; }

        public decimal EstimatedCost { get; init; }

        public decimal? SavingsVsTarget { get; init; }

        public DateOnly PriceRecordDate { get; init; }

        public DateTimeOffset ComputedAtUtc { get; init; }
    }

    private sealed class AdminCostComponentRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public string ComponentType { get; init; } = string.Empty;

        public decimal Value { get; init; }

        public bool IsActive { get; init; }
    }
#pragma warning restore CA1812
}
