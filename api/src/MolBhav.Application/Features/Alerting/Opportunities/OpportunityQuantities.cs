namespace MolBhav.Application.Features.Alerting.Opportunities;

/// <summary>
/// The order size landed prices assume is configured in quintals; a product priced per kg needs the same weight counted
/// in kg, so per-order costs are spread over the right number of units.
/// </summary>
internal static class OpportunityQuantities
{
    public static decimal For(decimal referenceQuintals, string unitCode) =>
        string.Equals(unitCode, "kg", StringComparison.OrdinalIgnoreCase) ? referenceQuintals * 100m : referenceQuintals;
}
