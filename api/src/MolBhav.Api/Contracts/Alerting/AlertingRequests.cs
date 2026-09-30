using MolBhav.Domain.Alerting;
using MolBhav.Domain.Pricing;

namespace MolBhav.Api.Contracts.Alerting;

/// <summary>
/// <c>ThresholdPercent</c> belongs to <c>PriceDrop</c>/<c>PriceSpike</c>, <c>ThresholdPrice</c> to
/// <c>PriceBelow</c>/<c>PriceAbove</c>; sending both (or the wrong one for the type) is a 400.
/// </summary>
public sealed record CreateAlertRuleRequest(
    Guid? ProductId,
    Guid? VariantId,
    LocationKind? LocationKind,
    Guid? MandiId,
    Guid? SupplierId,
    AlertThresholdType? ThresholdType,
    decimal? ThresholdPercent,
    decimal? ThresholdPrice);

/// <summary><c>IsActive</c> is required — there is no partial update, so a missing one can't silently deactivate a
/// rule — and the threshold field the rule's own type calls for must be sent.</summary>
public sealed record UpdateAlertRuleRequest(decimal? ThresholdPercent, decimal? ThresholdPrice, bool? IsActive);
