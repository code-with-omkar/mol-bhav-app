using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Support.Events;

/// <summary>
/// Raised when support answers a ticket. Consumed by the Notification module to tell the ticket's owner — the same
/// Pricing → Alerting → Notification chain shape, here Support → Notification.
/// </summary>
public sealed record SupportTicketRepliedDomainEvent(
    Guid TicketId,
    Guid UserId,
    Guid MessageId,
    SupportTicketCategory Category,
    string Subject,
    SupportTicketStatus Status) : DomainEvent;
