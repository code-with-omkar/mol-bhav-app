using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Alerting.Events;

/// <summary>
/// Raised when the daily scan finds a market where a watched product lands at least the configured percentage below
/// the user's home-district price. Consumed by the Notification module (push/WhatsApp per the user's alert switches).
/// </summary>
public sealed record MarketOpportunityFoundDomainEvent(
    Guid OpportunityId,
    Guid UserId,
    Guid ProductId,
    Guid? VariantId,
    decimal HomePrice,
    decimal BestPrice,
    decimal LandedPrice,
    decimal SavingsPercent) : DomainEvent;
