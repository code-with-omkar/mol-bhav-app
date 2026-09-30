using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Alerting;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Alerting.Models;

/// <summary>
/// A standing watch on a product's price. <see cref="LocationKind"/> null means product-wide; exactly one of
/// <c>ThresholdPercent</c> (percent types) and <c>ThresholdPrice</c> (price-level types) is set.
/// </summary>
public sealed record AlertRuleResponse(
    Guid Id,
    ProductSummaryResponse Product,
    Guid? VariantId,
    string? VariantName,
    LocationKind? LocationKind,
    Guid? MandiId,
    Guid? SupplierId,
    string? LocationName,
    AlertThresholdType ThresholdType,
    decimal? ThresholdPercent,
    decimal? ThresholdPrice,
    bool IsActive,
    DateTimeOffset CreatedAtUtc);

/// <summary>One triggered alert instance, newest first.</summary>
public sealed record AlertResponse(
    Guid Id,
    Guid AlertRuleId,
    ProductSummaryResponse Product,
    Guid? VariantId,
    string? VariantName,
    LocationKind LocationKind,
    Guid? MandiId,
    Guid? SupplierId,
    string? LocationName,
    decimal PreviousPrice,
    decimal NewPrice,
    decimal PercentChange,
    AlertThresholdType ThresholdType,
    DateTimeOffset TriggeredAtUtc,
    bool IsRead);
