using MolBhav.Domain.Catalog;

namespace MolBhav.Application.Features.Catalog.Models;

// Admin read models: every translation and inactive items included, so the admin portal can edit what it shows.

public sealed record TranslationResponse(string LanguageCode, string Name, string? Description);

public sealed record AdminCategoryResponse(
    Guid Id,
    string Code,
    string? IconKey,
    int DisplayOrder,
    bool IsActive,
    IReadOnlyList<TranslationResponse> Translations,
    IReadOnlyList<AdminSubCategoryResponse> SubCategories);

public sealed record AdminSubCategoryResponse(
    Guid Id,
    string Code,
    int DisplayOrder,
    bool IsActive,
    IReadOnlyList<TranslationResponse> Translations);

public sealed record AdminUnitResponse(
    Guid Id,
    string Code,
    string Symbol,
    MeasureDimension Dimension,
    decimal ToBaseFactor,
    bool IsActive,
    IReadOnlyList<TranslationResponse> Translations);

/// <summary>Admin product list row; <see cref="Name"/> is the English name.</summary>
public sealed record AdminProductSummaryResponse(
    Guid Id,
    string Code,
    string Name,
    string CategoryCode,
    Guid SubCategoryId,
    string SubCategoryCode,
    string DefaultUnitCode,
    int DisplayOrder,
    bool IsActive);

public sealed record AdminProductResponse(
    Guid Id,
    string Code,
    Guid SubCategoryId,
    Guid DefaultUnitId,
    int DisplayOrder,
    bool IsActive,
    string? ImageKey,
    IReadOnlyList<TranslationResponse> Translations,
    IReadOnlyList<AdminVariantResponse> Variants);

public sealed record AdminVariantResponse(
    Guid Id,
    string Code,
    int DisplayOrder,
    bool IsActive,
    IReadOnlyList<TranslationResponse> Translations);

/// <summary>Returned by every admin create command.</summary>
public sealed record CreatedResponse(Guid Id);
