using MolBhav.Domain.Procurement;

namespace MolBhav.Api.Contracts.Procurement;

public sealed record CreateRequirementRequest(
    Guid? ProductId,
    Guid? VariantId,
    decimal? Quantity,
    Guid? UnitId,
    Guid? TargetDistrictId,
    decimal? TargetPrice);

public sealed record CreateCostComponentRequest(string? Code, string? Name, CostComponentType? ComponentType, decimal? Value);

/// <summary>Both fields are required — there is no partial update, so a missing one can't silently deactivate a component.</summary>
public sealed record UpdateCostComponentRequest(string? Name, decimal? Value, bool? IsActive);
