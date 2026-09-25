using MolBhav.Domain.Catalog;

namespace MolBhav.Application.Features.Catalog.Models;

// Mobile read models: one resolved name per item, in the request language with fallback
// requested → configured default → English. Only active items are returned.

/// <summary>Select Category screen: a category with its active sub-categories.</summary>
public sealed record CategoryResponse(
    Guid Id,
    string Code,
    string Name,
    string? Description,
    string? IconKey,
    IReadOnlyList<SubCategoryResponse> SubCategories);

public sealed record SubCategoryResponse(Guid Id, string Code, string Name);

public sealed record UnitResponse(Guid Id, string Code, string Symbol, string Name, MeasureDimension Dimension, decimal ToBaseFactor);

public sealed record UnitSummaryResponse(Guid Id, string Code, string Symbol, string Name);

/// <summary>Product list row (category/product pickers, watchlist "add item").</summary>
public sealed record ProductSummaryResponse(
    Guid Id,
    string Code,
    string Name,
    Guid SubCategoryId,
    string SubCategoryName,
    UnitSummaryResponse DefaultUnit,
    string? ImageKey);

public sealed record CatalogReference(Guid Id, string Code, string Name);

public sealed record VariantResponse(Guid Id, string Code, string Name);

public sealed record ProductDetailResponse(
    Guid Id,
    string Code,
    string Name,
    string? Description,
    string? ImageKey,
    CatalogReference Category,
    CatalogReference SubCategory,
    UnitSummaryResponse DefaultUnit,
    IReadOnlyList<VariantResponse> Variants);
