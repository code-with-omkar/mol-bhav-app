using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Procurement;

/// <summary>
/// A user's standing "I need to buy this much of this" statement (BRD §13 Procurement Opportunity Engine). Matched
/// against live prices on demand (<c>ComputeOpportunitiesCommandHandler</c>) to produce <see cref="ProcurementOpportunity"/>
/// snapshots — the requirement itself carries no price data. Hard-deleted like <c>WatchlistItem</c>/<c>AlertRule</c>:
/// once withdrawn, a requirement carries no history worth keeping (its opportunity snapshots cascade with it).
/// </summary>
public sealed class ProcurementRequirement : AggregateRoot<Guid>, IAuditableEntity
{
    private ProcurementRequirement(
        Guid id,
        Guid userId,
        Guid productId,
        Guid? variantId,
        decimal quantity,
        Guid unitId,
        Guid? targetDistrictId,
        decimal? targetPrice)
        : base(id)
    {
        UserId = userId;
        ProductId = productId;
        VariantId = variantId;
        Quantity = quantity;
        UnitId = unitId;
        TargetDistrictId = targetDistrictId;
        TargetPrice = targetPrice;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private ProcurementRequirement()
    {
    }

    public Guid UserId { get; private set; }

    public Guid ProductId { get; private set; }

    public Guid? VariantId { get; private set; }

    public decimal Quantity { get; private set; }

    /// <summary>
    /// Must be the product's default unit — cross-unit conversion at opportunity-compute time is out of scope for
    /// this pass (BRD §25 lists full landed-cost/logistics modelling as a future enhancement); the caller (application
    /// layer) enforces the match against <c>Product.DefaultUnitId</c> before calling <see cref="Create"/>.
    /// </summary>
    public Guid UnitId { get; private set; }

    /// <summary>Optional: narrows the opportunity search to one district. Null searches every location for the product.</summary>
    public Guid? TargetDistrictId { get; private set; }

    /// <summary>Optional per-unit price the user hopes to beat — used to compute a saving/overage on each opportunity.</summary>
    public decimal? TargetPrice { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<ProcurementRequirement> Create(
        Guid userId,
        Guid productId,
        Guid? variantId,
        decimal quantity,
        Guid unitId,
        Guid? targetDistrictId,
        decimal? targetPrice)
    {
        if (userId == Guid.Empty || productId == Guid.Empty || unitId == Guid.Empty)
        {
            return Error.Validation("ProcurementRequirement.ReferenceRequired", "User, product and unit are required.");
        }

        if (quantity <= 0)
        {
            return Error.Validation("ProcurementRequirement.InvalidQuantity", "Quantity must be positive.");
        }

        if (targetPrice is { } price && price <= 0)
        {
            return Error.Validation("ProcurementRequirement.InvalidTargetPrice", "Target price must be positive when provided.");
        }

        return new ProcurementRequirement(Guid.CreateVersion7(), userId, productId, variantId, quantity, unitId, targetDistrictId, targetPrice);
    }
}
