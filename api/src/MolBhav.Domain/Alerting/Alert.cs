using MolBhav.Domain.Alerting.Events;
using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Pricing;

namespace MolBhav.Domain.Alerting;

/// <summary>
/// A single triggered instance of an <see cref="AlertRule"/> (BRD §15) — the immutable record shown in the user's
/// alert inbox. Created by <c>EvaluateAlertRulesHandler</c> whenever a new price crosses the owning rule's
/// threshold; never updated except to mark it read. No hard delete — unlike the rule itself, a fired alert is
/// history the user may want to review later.
/// </summary>
public sealed class Alert : AggregateRoot<Guid>, IAuditableEntity
{
    private Alert(
        Guid id,
        Guid alertRuleId,
        Guid userId,
        Guid productId,
        Guid? variantId,
        LocationKind locationKind,
        Guid? mandiId,
        Guid? supplierId,
        Guid priceRecordId,
        decimal previousPrice,
        decimal newPrice,
        decimal percentChange,
        AlertThresholdType thresholdType,
        DateTimeOffset triggeredAtUtc)
        : base(id)
    {
        AlertRuleId = alertRuleId;
        UserId = userId;
        ProductId = productId;
        VariantId = variantId;
        LocationKind = locationKind;
        MandiId = mandiId;
        SupplierId = supplierId;
        PriceRecordId = priceRecordId;
        PreviousPrice = previousPrice;
        NewPrice = newPrice;
        PercentChange = percentChange;
        ThresholdType = thresholdType;
        TriggeredAtUtc = triggeredAtUtc;
        IsRead = false;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private Alert()
    {
    }

    public Guid AlertRuleId { get; private set; }

    public Guid UserId { get; private set; }

    public Guid ProductId { get; private set; }

    public Guid? VariantId { get; private set; }

    public LocationKind LocationKind { get; private set; }

    public Guid? MandiId { get; private set; }

    public Guid? SupplierId { get; private set; }

    /// <summary>The price record that triggered this alert.</summary>
    public Guid PriceRecordId { get; private set; }

    public decimal PreviousPrice { get; private set; }

    public decimal NewPrice { get; private set; }

    /// <summary>Signed percent change vs. <see cref="PreviousPrice"/> — negative for a drop, positive for a spike.</summary>
    public decimal PercentChange { get; private set; }

    public AlertThresholdType ThresholdType { get; private set; }

    public DateTimeOffset TriggeredAtUtc { get; private set; }

    public bool IsRead { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    /// <summary>
    /// Records that <paramref name="rule"/> fired for a newly-recorded price. The caller (evaluation handler) has
    /// already confirmed the threshold was crossed; this factory only re-asserts the invariants and raises the
    /// event for Notification to pick up.
    /// </summary>
    public static Result<Alert> Create(
        AlertRule rule,
        Guid priceRecordId,
        LocationKind locationKind,
        Guid? mandiId,
        Guid? supplierId,
        decimal previousPrice,
        decimal newPrice,
        decimal percentChange,
        DateTimeOffset triggeredAtUtc)
    {
        ArgumentNullException.ThrowIfNull(rule);

        if (previousPrice <= 0 || newPrice <= 0)
        {
            return Error.Validation("Alert.InvalidPrice", "Previous and new price must both be positive.");
        }

        var alert = new Alert(
            Guid.CreateVersion7(),
            rule.Id,
            rule.UserId,
            rule.ProductId,
            rule.VariantId,
            locationKind,
            mandiId,
            supplierId,
            priceRecordId,
            previousPrice,
            newPrice,
            percentChange,
            rule.ThresholdType,
            triggeredAtUtc);

        alert.RaiseDomainEvent(new AlertTriggeredDomainEvent(
            alert.Id,
            alert.UserId,
            alert.AlertRuleId,
            alert.ProductId,
            alert.VariantId,
            alert.LocationKind,
            alert.MandiId,
            alert.SupplierId,
            alert.PreviousPrice,
            alert.NewPrice,
            alert.PercentChange,
            alert.ThresholdType));

        return alert;
    }

    public void MarkRead() => IsRead = true;
}
