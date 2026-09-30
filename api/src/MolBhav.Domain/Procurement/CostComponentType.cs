namespace MolBhav.Domain.Procurement;

/// <summary>How a <see cref="CostComponent"/>'s <c>Value</c> is applied on top of the base price × quantity (BRD §17/§25 —
/// freight/handling/tax/supplier-terms are explicitly future-facing "landed cost" inputs; this is the extensible slot for them).</summary>
public enum CostComponentType
{
    /// <summary>Value is a percentage of the base cost (price × quantity), e.g. a 2% commission.</summary>
    Percentage = 0,

    /// <summary>Value is a flat amount added regardless of quantity, e.g. a fixed loading charge.</summary>
    Fixed = 1,
}
