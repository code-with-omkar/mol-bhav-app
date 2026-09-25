using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;

namespace MolBhav.Api.Contracts.Catalog;

// Admin portal request bodies. PUTs are full replacements. Everything is nullable so a missing field reaches
// FluentValidation (one error shape, explicit "required" messages) instead of silently binding to a default —
// an omitted isActive must never deactivate an item.
// translations: [{ "languageCode": "en", "name": "Onion", "description": null }, { "languageCode": "mr", "name": "कांदा" }]
// English is required; only enabled languages are accepted.

public sealed record CreateCategoryRequest(
    string? Code,
    string? IconKey,
    int? DisplayOrder,
    IReadOnlyCollection<TranslationInput>? Translations);

public sealed record UpdateCategoryRequest(
    string? IconKey,
    int? DisplayOrder,
    bool? IsActive,
    IReadOnlyCollection<TranslationInput>? Translations);

public sealed record AddSubCategoryRequest(
    string? Code,
    int? DisplayOrder,
    IReadOnlyCollection<TranslationInput>? Translations);

public sealed record UpdateSubCategoryRequest(
    int? DisplayOrder,
    bool? IsActive,
    IReadOnlyCollection<TranslationInput>? Translations);

/// <param name="Code">Immutable, e.g. <c>bag-25kg</c>.</param>
/// <param name="Symbol">Short display symbol, e.g. <c>bag</c>.</param>
/// <param name="Dimension">Mass, Volume, Count, Length or Area. Immutable after creation.</param>
/// <param name="ToBaseFactor">Base units per one of this unit: kg (mass), m³ (volume), piece (count), m (length), m² (area). Immutable after creation.</param>
/// <param name="Translations">English required.</param>
public sealed record CreateUnitRequest(
    string? Code,
    string? Symbol,
    MeasureDimension? Dimension,
    decimal? ToBaseFactor,
    IReadOnlyCollection<TranslationInput>? Translations);

public sealed record UpdateUnitRequest(
    string? Symbol,
    bool? IsActive,
    IReadOnlyCollection<TranslationInput>? Translations);

public sealed record CreateProductRequest(
    string? Code,
    Guid? SubCategoryId,
    Guid? DefaultUnitId,
    int? DisplayOrder,
    string? ImageKey,
    IReadOnlyCollection<TranslationInput>? Translations);

public sealed record UpdateProductRequest(
    Guid? SubCategoryId,
    Guid? DefaultUnitId,
    int? DisplayOrder,
    bool? IsActive,
    string? ImageKey,
    IReadOnlyCollection<TranslationInput>? Translations);

public sealed record AddVariantRequest(
    string? Code,
    int? DisplayOrder,
    IReadOnlyCollection<TranslationInput>? Translations);

public sealed record UpdateVariantRequest(
    int? DisplayOrder,
    bool? IsActive,
    IReadOnlyCollection<TranslationInput>? Translations);
