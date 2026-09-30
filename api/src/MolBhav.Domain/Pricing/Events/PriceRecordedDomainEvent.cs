using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Pricing.Events;

/// <summary>
/// Raised when a new, non-voided <see cref="PriceRecord"/> is successfully created.
/// Consumed by the Alerting module to evaluate whether any active alert rules are crossed.
/// </summary>
public sealed record PriceRecordedDomainEvent(
    Guid PriceRecordId,
    Guid ProductId,
    Guid? VariantId,
    LocationKind LocationKind,
    Guid? MandiId,
    Guid? SupplierId,
    decimal ModalPrice,
    DateOnly RecordDate) : DomainEvent;
