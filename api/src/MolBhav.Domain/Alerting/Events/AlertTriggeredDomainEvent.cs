using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Pricing;

namespace MolBhav.Domain.Alerting.Events;

/// <summary>
/// Raised when a new price crosses an <see cref="AlertRule"/>'s threshold and an <see cref="Alert"/> instance is
/// created for the user. Consumed by the Notification module to push/WhatsApp the user.
/// </summary>
public sealed record AlertTriggeredDomainEvent(
    Guid AlertId,
    Guid UserId,
    Guid AlertRuleId,
    Guid ProductId,
    Guid? VariantId,
    LocationKind LocationKind,
    Guid? MandiId,
    Guid? SupplierId,
    decimal PreviousPrice,
    decimal NewPrice,
    decimal PercentChange,
    AlertThresholdType ThresholdType) : DomainEvent;
