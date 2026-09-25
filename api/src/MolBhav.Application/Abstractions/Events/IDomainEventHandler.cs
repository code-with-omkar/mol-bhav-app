using MolBhav.Domain.Common.Abstractions;

namespace MolBhav.Application.Abstractions.Events;

/// <summary>
/// Reacts to a domain event dispatched from the transactional outbox.
/// Delivery is at-least-once: implementations must be idempotent (e.g. check EventId before side effects).
/// Each event is handled in its own DI scope with its own unit of work.
/// </summary>
public interface IDomainEventHandler<in TEvent>
    where TEvent : IDomainEvent
{
    Task HandleAsync(TEvent domainEvent, CancellationToken cancellationToken);
}
