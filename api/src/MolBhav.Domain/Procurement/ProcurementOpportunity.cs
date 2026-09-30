using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Pricing;

namespace MolBhav.Domain.Procurement;

/// <summary>
/// A computed snapshot of what buying one <see cref="ProcurementRequirement"/>'s quantity would cost at one
/// location, as of the moment it was computed (BRD §13/§17). Location name/price are denormalized at compute time
/// rather than FK'd to the live price record — the point of the snapshot is "what we saw then", which must survive
/// the underlying price row being superseded by a newer one. No hard delete: opportunities are the requirement's
/// history and are removed only when the requirement itself is (cascade).
/// </summary>
public sealed class ProcurementOpportunity : AggregateRoot<Guid>, IAuditableEntity
{
    private ProcurementOpportunity(
        Guid id,
        Guid requirementId,
        LocationKind locationKind,
        Guid locationId,
        string locationName,
        decimal quantity,
        decimal unitPrice,
        decimal estimatedCost,
        decimal? savingsVsTarget,
        DateOnly priceRecordDate,
        DateTimeOffset computedAtUtc)
        : base(id)
    {
        RequirementId = requirementId;
        LocationKind = locationKind;
        LocationId = locationId;
        LocationName = locationName;
        Quantity = quantity;
        UnitPrice = unitPrice;
        EstimatedCost = estimatedCost;
        SavingsVsTarget = savingsVsTarget;
        PriceRecordDate = priceRecordDate;
        ComputedAtUtc = computedAtUtc;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private ProcurementOpportunity()
    {
        LocationName = string.Empty;
    }

    public Guid RequirementId { get; private set; }

    public LocationKind LocationKind { get; private set; }

    public Guid LocationId { get; private set; }

    public string LocationName { get; private set; }

    public decimal Quantity { get; private set; }

    /// <summary>The price per unit found at this location at compute time.</summary>
    public decimal UnitPrice { get; private set; }

    /// <summary>Quantity × unit price, plus every active <see cref="CostComponent"/> applied at compute time.</summary>
    public decimal EstimatedCost { get; private set; }

    /// <summary>Positive when this opportunity beats the requirement's target price × quantity; null if no target was set.</summary>
    public decimal? SavingsVsTarget { get; private set; }

    /// <summary>Freshness of the underlying price — surfaced so the user knows how current the estimate is (BRD §13).</summary>
    public DateOnly PriceRecordDate { get; private set; }

    public DateTimeOffset ComputedAtUtc { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<ProcurementOpportunity> Create(
        Guid requirementId,
        LocationKind locationKind,
        Guid locationId,
        string? locationName,
        decimal quantity,
        decimal unitPrice,
        decimal estimatedCost,
        decimal? savingsVsTarget,
        DateOnly priceRecordDate,
        DateTimeOffset computedAtUtc)
    {
        if (requirementId == Guid.Empty || locationId == Guid.Empty)
        {
            return Error.Validation("ProcurementOpportunity.ReferenceRequired", "Requirement and location are required.");
        }

        if (string.IsNullOrWhiteSpace(locationName))
        {
            return Error.Validation("ProcurementOpportunity.LocationNameRequired", "Location name is required.");
        }

        if (quantity <= 0 || unitPrice <= 0 || estimatedCost < 0)
        {
            return Error.Validation("ProcurementOpportunity.InvalidAmounts", "Quantity and unit price must be positive.");
        }

        return new ProcurementOpportunity(
            Guid.CreateVersion7(),
            requirementId,
            locationKind,
            locationId,
            locationName.Trim(),
            quantity,
            unitPrice,
            estimatedCost,
            savingsVsTarget,
            priceRecordDate,
            computedAtUtc);
    }
}
