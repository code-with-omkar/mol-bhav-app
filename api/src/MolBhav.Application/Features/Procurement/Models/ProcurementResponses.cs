using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Pricing;
using MolBhav.Domain.Procurement;

namespace MolBhav.Application.Features.Procurement.Models;

public sealed record ProcurementRequirementResponse(
    Guid Id,
    ProductSummaryResponse Product,
    Guid? VariantId,
    string? VariantName,
    decimal Quantity,
    UnitSummaryResponse Unit,
    Guid? TargetDistrictId,
    string? TargetDistrictName,
    decimal? TargetPrice,
    DateTimeOffset CreatedAtUtc);

public sealed record ProcurementOpportunityResponse(
    Guid Id,
    LocationKind LocationKind,
    Guid LocationId,
    string LocationName,
    decimal Quantity,
    decimal UnitPrice,
    decimal EstimatedCost,
    decimal? SavingsVsTarget,
    DateOnly PriceRecordDate,
    DateTimeOffset ComputedAtUtc);

public sealed record AdminCostComponentResponse(Guid Id, string Code, string Name, CostComponentType ComponentType, decimal Value, bool IsActive);
