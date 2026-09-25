using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Abstractions.Catalog;

/// <summary>Dapper-backed catalog reads for the mobile screens and the admin portal.</summary>
public interface ICatalogReadService
{
    Task<IReadOnlyList<CategoryResponse>> GetCategoriesAsync(LanguagePreference language, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<UnitResponse>> GetUnitsAsync(LanguagePreference language, CancellationToken cancellationToken = default);

    /// <summary>Null when the category does not exist or is inactive.</summary>
    Task<PagedResult<ProductSummaryResponse>?> GetProductsAsync(ProductListFilter filter, LanguagePreference language, CancellationToken cancellationToken = default);

    /// <summary>Null when the product (or its sub-category/category) does not exist or is inactive.</summary>
    Task<ProductDetailResponse?> GetProductAsync(Guid productId, LanguagePreference language, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AdminCategoryResponse>> GetAdminCategoriesAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AdminUnitResponse>> GetAdminUnitsAsync(CancellationToken cancellationToken = default);

    Task<PagedResult<AdminProductSummaryResponse>> GetAdminProductsAsync(AdminProductFilter filter, CancellationToken cancellationToken = default);

    Task<AdminProductResponse?> GetAdminProductAsync(Guid productId, CancellationToken cancellationToken = default);
}

/// <summary>Name resolution order: <see cref="Requested"/> → <see cref="Default"/> → English (always present).</summary>
public sealed record LanguagePreference(string Requested, string Default);

public sealed record ProductListFilter(string CategoryCode, Guid? SubCategoryId, string? Search, PageRequest Page);

public sealed record AdminProductFilter(string? CategoryCode, Guid? SubCategoryId, string? Search, bool? IsActive, PageRequest Page);
