using Dapper;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.SharedKernel;
using MolBhav.Infrastructure.Persistence.Configurations.Catalog;

namespace MolBhav.Infrastructure.Persistence.Read.Catalog;

/// <summary>
/// Catalog reads for the mobile screens (one resolved name per item, active items only) and the admin portal
/// (every translation, inactive included). All SQL is parameterised; table names are compile-time constants.
/// </summary>
internal sealed class CatalogReadService(IDbConnectionFactory connectionFactory) : ICatalogReadService
{
    private const string Categories = Schemas.Catalog + "." + ProcurementCategoryConfiguration.TableName;
    private const string CategoryTranslations = Schemas.Catalog + "." + ProcurementCategoryConfiguration.TranslationsTableName;
    private const string SubCategories = Schemas.Catalog + "." + SubCategoryConfiguration.TableName;
    private const string SubCategoryTranslations = Schemas.Catalog + "." + SubCategoryConfiguration.TranslationsTableName;
    private const string Products = Schemas.Catalog + "." + ProductConfiguration.TableName;
    private const string ProductTranslations = Schemas.Catalog + "." + ProductConfiguration.TranslationsTableName;
    private const string Variants = Schemas.Catalog + "." + ProductVariantConfiguration.TableName;
    private const string VariantTranslations = Schemas.Catalog + "." + ProductVariantConfiguration.TranslationsTableName;
    private const string Units = Schemas.Catalog + "." + UnitOfMeasureConfiguration.TableName;
    private const string UnitTranslations = Schemas.Catalog + "." + UnitOfMeasureConfiguration.TranslationsTableName;

    private static readonly string CategoryName = NameLateral(CategoryTranslations, "category_id", "c", "cn");
    private static readonly string SubCategoryName = NameLateral(SubCategoryTranslations, "sub_category_id", "s", "sn");
    private static readonly string ProductName = NameLateral(ProductTranslations, "product_id", "p", "pn");
    private static readonly string VariantName = NameLateral(VariantTranslations, "variant_id", "v", "vn");
    private static readonly string UnitName = NameLateral(UnitTranslations, "unit_id", "u", "un");
    private static readonly string EnglishProductName = EnglishLateral(ProductTranslations, "product_id", "p", "pn");

    // ---------------------------------------------------------------- mobile

    private static readonly string CategoriesSql = $"""
        SELECT c.id, c.code, c.icon_key, cn.name, cn.description
        FROM {Categories} c
        {CategoryName}
        WHERE c.is_active
        ORDER BY c.display_order, c.code;

        SELECT s.id, s.category_id, s.code, sn.name
        FROM {SubCategories} s
        JOIN {Categories} c ON c.id = s.category_id AND c.is_active
        {SubCategoryName}
        WHERE s.is_active
        ORDER BY s.display_order, s.code;
        """;

    private static readonly string UnitsSql = $"""
        SELECT u.id, u.code, u.symbol, un.name, u.dimension, u.to_base_factor
        FROM {Units} u
        {UnitName}
        WHERE u.is_active
        ORDER BY u.dimension, u.to_base_factor, u.code;
        """;

    private const string ActiveCategoryIdSql = $"""
        SELECT c.id FROM {Categories} c WHERE c.code = @CategoryCode AND c.is_active;
        """;

    /// <summary>Shared FROM for the product list and its count.</summary>
    private const string ProductListFrom = $"""
        FROM {Products} p
        JOIN {SubCategories} s ON s.id = p.sub_category_id AND s.is_active AND s.category_id = @CategoryId
        """;

    /// <summary>
    /// Shared WHERE for the product list and its count. Search matches the code or a name in any language
    /// (served by the trigram GIN index on product_translations.name).
    /// </summary>
    private const string ProductListWhere = $"""
        WHERE p.is_active
          AND (@SubCategoryId::uuid IS NULL OR p.sub_category_id = @SubCategoryId::uuid)
          AND (@Pattern::text IS NULL
               OR p.code ILIKE @Pattern::text
               OR EXISTS (SELECT 1 FROM {ProductTranslations} t WHERE t.product_id = p.id AND t.name ILIKE @Pattern::text))
        """;

    private static readonly string ProductListSql = $"""
        SELECT count(*)
        {ProductListFrom}
        {ProductListWhere};

        SELECT p.id, p.code, pn.name, p.sub_category_id, sn.name AS sub_category_name,
               u.id AS unit_id, u.code AS unit_code, u.symbol AS unit_symbol, un.name AS unit_name, p.image_key
        {ProductListFrom}
        JOIN {Units} u ON u.id = p.default_unit_id
        {ProductName}
        {SubCategoryName}
        {UnitName}
        {ProductListWhere}
        ORDER BY s.display_order, p.display_order, p.code
        LIMIT @Limit OFFSET @Offset;
        """;

    private static readonly string ProductDetailSql = $"""
        SELECT p.id, p.code, pn.name, pn.description, p.image_key,
               c.id AS category_id, c.code AS category_code, cn.name AS category_name,
               s.id AS sub_category_id, s.code AS sub_category_code, sn.name AS sub_category_name,
               u.id AS unit_id, u.code AS unit_code, u.symbol AS unit_symbol, un.name AS unit_name
        FROM {Products} p
        JOIN {SubCategories} s ON s.id = p.sub_category_id
        JOIN {Categories} c ON c.id = s.category_id
        JOIN {Units} u ON u.id = p.default_unit_id
        {ProductName}
        {SubCategoryName}
        {CategoryName}
        {UnitName}
        WHERE p.id = @ProductId AND p.is_active AND s.is_active AND c.is_active;

        SELECT v.id, v.code, vn.name
        FROM {Variants} v
        {VariantName}
        WHERE v.product_id = @ProductId AND v.is_active
        ORDER BY v.display_order, v.code;
        """;

    // ---------------------------------------------------------------- admin

    private const string AdminCategoriesSql = $"""
        SELECT c.id, c.code, c.icon_key, c.display_order, c.is_active
        FROM {Categories} c ORDER BY c.display_order, c.code;

        SELECT t.category_id AS owner_id, t.language_code, t.name, t.description
        FROM {CategoryTranslations} t ORDER BY t.language_code;

        SELECT s.id, s.category_id, s.code, s.display_order, s.is_active
        FROM {SubCategories} s ORDER BY s.display_order, s.code;

        SELECT t.sub_category_id AS owner_id, t.language_code, t.name, t.description
        FROM {SubCategoryTranslations} t ORDER BY t.language_code;
        """;

    private const string AdminUnitsSql = $"""
        SELECT u.id, u.code, u.symbol, u.dimension, u.to_base_factor, u.is_active
        FROM {Units} u ORDER BY u.dimension, u.to_base_factor, u.code;

        SELECT t.unit_id AS owner_id, t.language_code, t.name, t.description
        FROM {UnitTranslations} t ORDER BY t.language_code;
        """;

    private const string AdminProductListFrom = $"""
        FROM {Products} p
        JOIN {SubCategories} s ON s.id = p.sub_category_id
        JOIN {Categories} c ON c.id = s.category_id
        """;

    private const string AdminProductListWhere = $"""
        WHERE (@CategoryCode::text IS NULL OR c.code = @CategoryCode::text)
          AND (@SubCategoryId::uuid IS NULL OR p.sub_category_id = @SubCategoryId::uuid)
          AND (@IsActive::boolean IS NULL OR p.is_active = @IsActive::boolean)
          AND (@Pattern::text IS NULL
               OR p.code ILIKE @Pattern::text
               OR EXISTS (SELECT 1 FROM {ProductTranslations} t WHERE t.product_id = p.id AND t.name ILIKE @Pattern::text))
        """;

    private static readonly string AdminProductListSql = $"""
        SELECT count(*)
        {AdminProductListFrom}
        {AdminProductListWhere};

        SELECT p.id, p.code, pn.name, c.code AS category_code, p.sub_category_id, s.code AS sub_category_code,
               u.code AS default_unit_code, p.display_order, p.is_active
        {AdminProductListFrom}
        JOIN {Units} u ON u.id = p.default_unit_id
        {EnglishProductName}
        {AdminProductListWhere}
        ORDER BY c.display_order, s.display_order, p.display_order, p.code
        LIMIT @Limit OFFSET @Offset;
        """;

    private const string AdminProductSql = $"""
        SELECT p.id, p.code, p.sub_category_id, p.default_unit_id, p.display_order, p.is_active, p.image_key
        FROM {Products} p WHERE p.id = @ProductId;

        SELECT t.product_id AS owner_id, t.language_code, t.name, t.description
        FROM {ProductTranslations} t WHERE t.product_id = @ProductId ORDER BY t.language_code;

        SELECT v.id, v.code, v.display_order, v.is_active
        FROM {Variants} v WHERE v.product_id = @ProductId ORDER BY v.display_order, v.code;

        SELECT t.variant_id AS owner_id, t.language_code, t.name, t.description
        FROM {VariantTranslations} t
        JOIN {Variants} v ON v.id = t.variant_id
        WHERE v.product_id = @ProductId ORDER BY t.language_code;
        """;

    public async Task<IReadOnlyList<CategoryResponse>> GetCategoriesAsync(LanguagePreference language, CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(CategoriesSql, LanguageArgs(language), cancellationToken));

        var categories = (await grid.ReadAsync<CategoryRow>()).AsList();
        var subCategories = (await grid.ReadAsync<SubCategoryRow>()).ToLookup(s => s.CategoryId);

        return categories
            .Select(c => new CategoryResponse(
                c.Id,
                c.Code,
                c.Name,
                c.Description,
                c.IconKey,
                subCategories[c.Id].Select(s => new SubCategoryResponse(s.Id, s.Code, s.Name)).ToArray()))
            .ToArray();
    }

    public async Task<IReadOnlyList<UnitResponse>> GetUnitsAsync(LanguagePreference language, CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<UnitRow>(Command(UnitsSql, LanguageArgs(language), cancellationToken));

        return rows
            .Select(u => new UnitResponse(u.Id, u.Code, u.Symbol, u.Name, ParseDimension(u.Dimension), TrimScale(u.ToBaseFactor)))
            .ToArray();
    }

    public async Task<PagedResult<ProductSummaryResponse>?> GetProductsAsync(
        ProductListFilter filter,
        LanguagePreference language,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);

        var categoryId = await connection.QuerySingleOrDefaultAsync<Guid?>(
            Command(ActiveCategoryIdSql, new { filter.CategoryCode }, cancellationToken));

        if (categoryId is null)
        {
            return null;
        }

        var args = new DynamicParameters(LanguageArgs(language));
        args.Add("CategoryId", categoryId.Value);
        args.Add("SubCategoryId", filter.SubCategoryId);
        args.Add("Pattern", ContainsPattern(filter.Search));
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var grid = await connection.QueryMultipleAsync(Command(ProductListSql, args, cancellationToken));
        var total = await grid.ReadSingleAsync<long>();
        var items = (await grid.ReadAsync<ProductListRow>())
            .Select(p => new ProductSummaryResponse(
                p.Id,
                p.Code,
                p.Name,
                p.SubCategoryId,
                p.SubCategoryName,
                new UnitSummaryResponse(p.UnitId, p.UnitCode, p.UnitSymbol, p.UnitName),
                p.ImageKey))
            .ToArray();

        return new PagedResult<ProductSummaryResponse>(items, filter.Page.Page, filter.Page.PageSize, total);
    }

    public async Task<ProductDetailResponse?> GetProductAsync(Guid productId, LanguagePreference language, CancellationToken cancellationToken = default)
    {
        var args = new DynamicParameters(LanguageArgs(language));
        args.Add("ProductId", productId);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(ProductDetailSql, args, cancellationToken));

        var product = await grid.ReadSingleOrDefaultAsync<ProductDetailRow>();
        if (product is null)
        {
            return null;
        }

        var variants = (await grid.ReadAsync<VariantRow>())
            .Select(v => new VariantResponse(v.Id, v.Code, v.Name))
            .ToArray();

        return new ProductDetailResponse(
            product.Id,
            product.Code,
            product.Name,
            product.Description,
            product.ImageKey,
            new CatalogReference(product.CategoryId, product.CategoryCode, product.CategoryName),
            new CatalogReference(product.SubCategoryId, product.SubCategoryCode, product.SubCategoryName),
            new UnitSummaryResponse(product.UnitId, product.UnitCode, product.UnitSymbol, product.UnitName),
            variants);
    }

    public async Task<IReadOnlyList<AdminCategoryResponse>> GetAdminCategoriesAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminCategoriesSql, null, cancellationToken));

        var categories = (await grid.ReadAsync<AdminCategoryRow>()).AsList();
        var categoryTranslations = await ReadTranslationsAsync(grid);
        var subCategories = (await grid.ReadAsync<AdminSubCategoryRow>()).ToLookup(s => s.CategoryId);
        var subCategoryTranslations = await ReadTranslationsAsync(grid);

        return categories
            .Select(c => new AdminCategoryResponse(
                c.Id,
                c.Code,
                c.IconKey,
                c.DisplayOrder,
                c.IsActive,
                categoryTranslations[c.Id].ToArray(),
                subCategories[c.Id]
                    .Select(s => new AdminSubCategoryResponse(s.Id, s.Code, s.DisplayOrder, s.IsActive, subCategoryTranslations[s.Id].ToArray()))
                    .ToArray()))
            .ToArray();
    }

    public async Task<IReadOnlyList<AdminUnitResponse>> GetAdminUnitsAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminUnitsSql, null, cancellationToken));

        var units = (await grid.ReadAsync<AdminUnitRow>()).AsList();
        var translations = await ReadTranslationsAsync(grid);

        return units
            .Select(u => new AdminUnitResponse(
                u.Id,
                u.Code,
                u.Symbol,
                ParseDimension(u.Dimension),
                TrimScale(u.ToBaseFactor),
                u.IsActive,
                translations[u.Id].ToArray()))
            .ToArray();
    }

    public async Task<PagedResult<AdminProductSummaryResponse>> GetAdminProductsAsync(AdminProductFilter filter, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(filter);

        var args = new DynamicParameters();
        args.Add("CategoryCode", filter.CategoryCode);
        args.Add("SubCategoryId", filter.SubCategoryId);
        args.Add("IsActive", filter.IsActive);
        args.Add("Pattern", ContainsPattern(filter.Search));
        args.Add("Limit", filter.Page.PageSize);
        args.Add("Offset", filter.Page.Offset);

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminProductListSql, args, cancellationToken));

        var total = await grid.ReadSingleAsync<long>();
        var items = (await grid.ReadAsync<AdminProductListRow>())
            .Select(p => new AdminProductSummaryResponse(
                p.Id,
                p.Code,
                p.Name,
                p.CategoryCode,
                p.SubCategoryId,
                p.SubCategoryCode,
                p.DefaultUnitCode,
                p.DisplayOrder,
                p.IsActive))
            .ToArray();

        return new PagedResult<AdminProductSummaryResponse>(items, filter.Page.Page, filter.Page.PageSize, total);
    }

    public async Task<AdminProductResponse?> GetAdminProductAsync(Guid productId, CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        await using var grid = await connection.QueryMultipleAsync(Command(AdminProductSql, new { ProductId = productId }, cancellationToken));

        var product = await grid.ReadSingleOrDefaultAsync<AdminProductRow>();
        if (product is null)
        {
            return null;
        }

        var translations = await ReadTranslationsAsync(grid);
        var variants = (await grid.ReadAsync<AdminVariantRow>()).AsList();
        var variantTranslations = await ReadTranslationsAsync(grid);

        return new AdminProductResponse(
            product.Id,
            product.Code,
            product.SubCategoryId,
            product.DefaultUnitId,
            product.DisplayOrder,
            product.IsActive,
            product.ImageKey,
            translations[product.Id].ToArray(),
            variants
                .Select(v => new AdminVariantResponse(v.Id, v.Code, v.DisplayOrder, v.IsActive, variantTranslations[v.Id].ToArray()))
                .ToArray());
    }

    /// <summary>
    /// Best available name for one row: requested language, else the configured default, else English (always present
    /// — enforced by the domain). One index seek on the translation PK (owner_id, language_code).
    /// </summary>
    private static string NameLateral(string translationTable, string ownerColumn, string ownerAlias, string alias) => $"""
        LEFT JOIN LATERAL (
            SELECT t.name, t.description
            FROM {translationTable} t
            WHERE t.{ownerColumn} = {ownerAlias}.id AND t.language_code IN (@Lang, @DefaultLang, 'en')
            ORDER BY CASE t.language_code WHEN @Lang THEN 0 WHEN @DefaultLang THEN 1 ELSE 2 END
            LIMIT 1
        ) {alias} ON TRUE
        """;

    private static string EnglishLateral(string translationTable, string ownerColumn, string ownerAlias, string alias) => $"""
        LEFT JOIN LATERAL (
            SELECT t.name FROM {translationTable} t WHERE t.{ownerColumn} = {ownerAlias}.id AND t.language_code = 'en'
        ) {alias} ON TRUE
        """;

    private static object LanguageArgs(LanguagePreference language)
    {
        ArgumentNullException.ThrowIfNull(language);
        return new { Lang = language.Requested, DefaultLang = language.Default };
    }

    /// <summary>ILIKE "contains" pattern with the user's text escaped, so % and _ are matched literally.</summary>
    private static string? ContainsPattern(string? search)
    {
        if (string.IsNullOrWhiteSpace(search))
        {
            return null;
        }

        var escaped = search.Trim()
            .Replace(@"\", @"\\", StringComparison.Ordinal)
            .Replace("%", @"\%", StringComparison.Ordinal)
            .Replace("_", @"\_", StringComparison.Ordinal);

        return $"%{escaped}%";
    }

    private static CommandDefinition Command(string sql, object? args, CancellationToken cancellationToken) =>
        new(sql, args, cancellationToken: cancellationToken);

    private static async Task<ILookup<Guid, TranslationResponse>> ReadTranslationsAsync(SqlMapper.GridReader grid) =>
        (await grid.ReadAsync<TranslationRow>())
            .ToLookup(t => t.OwnerId, t => new TranslationResponse(t.LanguageCode.Trim(), t.Name, t.Description));

    /// <summary>numeric(18,6) comes back with scale 6 (100.000000); dividing by 1.000… drops the trailing zeros (100).</summary>
    private static decimal TrimScale(decimal value) => value / 1.0000000000000000000000000000m;

    private static MeasureDimension ParseDimension(string value) => Enum.Parse<MeasureDimension>(value, ignoreCase: false);

    // Flat row shapes for Dapper (snake_case → PascalCase via MatchNamesWithUnderscores).
#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class CategoryRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string? IconKey { get; init; }

        public string Name { get; init; } = string.Empty;

        public string? Description { get; init; }
    }

    private sealed class SubCategoryRow
    {
        public Guid Id { get; init; }

        public Guid CategoryId { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;
    }

    private sealed class UnitRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Symbol { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public string Dimension { get; init; } = string.Empty;

        public decimal ToBaseFactor { get; init; }
    }

    private sealed class ProductListRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public Guid SubCategoryId { get; init; }

        public string SubCategoryName { get; init; } = string.Empty;

        public Guid UnitId { get; init; }

        public string UnitCode { get; init; } = string.Empty;

        public string UnitSymbol { get; init; } = string.Empty;

        public string UnitName { get; init; } = string.Empty;

        public string? ImageKey { get; init; }
    }

    private sealed class ProductDetailRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public string? Description { get; init; }

        public string? ImageKey { get; init; }

        public Guid CategoryId { get; init; }

        public string CategoryCode { get; init; } = string.Empty;

        public string CategoryName { get; init; } = string.Empty;

        public Guid SubCategoryId { get; init; }

        public string SubCategoryCode { get; init; } = string.Empty;

        public string SubCategoryName { get; init; } = string.Empty;

        public Guid UnitId { get; init; }

        public string UnitCode { get; init; } = string.Empty;

        public string UnitSymbol { get; init; } = string.Empty;

        public string UnitName { get; init; } = string.Empty;
    }

    private sealed class VariantRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;
    }

    private sealed class TranslationRow
    {
        public Guid OwnerId { get; init; }

        public string LanguageCode { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public string? Description { get; init; }
    }

    private sealed class AdminCategoryRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string? IconKey { get; init; }

        public int DisplayOrder { get; init; }

        public bool IsActive { get; init; }
    }

    private sealed class AdminSubCategoryRow
    {
        public Guid Id { get; init; }

        public Guid CategoryId { get; init; }

        public string Code { get; init; } = string.Empty;

        public int DisplayOrder { get; init; }

        public bool IsActive { get; init; }
    }

    private sealed class AdminVariantRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public int DisplayOrder { get; init; }

        public bool IsActive { get; init; }
    }

    private sealed class AdminUnitRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Symbol { get; init; } = string.Empty;

        public string Dimension { get; init; } = string.Empty;

        public decimal ToBaseFactor { get; init; }

        public bool IsActive { get; init; }
    }

    private sealed class AdminProductListRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public string Name { get; init; } = string.Empty;

        public string CategoryCode { get; init; } = string.Empty;

        public Guid SubCategoryId { get; init; }

        public string SubCategoryCode { get; init; } = string.Empty;

        public string DefaultUnitCode { get; init; } = string.Empty;

        public int DisplayOrder { get; init; }

        public bool IsActive { get; init; }
    }

    private sealed class AdminProductRow
    {
        public Guid Id { get; init; }

        public string Code { get; init; } = string.Empty;

        public Guid SubCategoryId { get; init; }

        public Guid DefaultUnitId { get; init; }

        public int DisplayOrder { get; init; }

        public bool IsActive { get; init; }

        public string? ImageKey { get; init; }
    }
#pragma warning restore CA1812
}
