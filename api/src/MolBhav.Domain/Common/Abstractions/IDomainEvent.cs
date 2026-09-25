namespace MolBhav.Domain.Common.Abstractions;

/// <summary>
/// Marker for something meaningful that happened inside an aggregate.
/// Events are persisted to the transactional outbox in the same transaction as the aggregate
/// and dispatched asynchronously, so implementations must be immutable and JSON-serialisable.
/// </summary>
public interface IDomainEvent
{
    Guid EventId { get; }

    DateTimeOffset OccurredAtUtc { get; }
}
