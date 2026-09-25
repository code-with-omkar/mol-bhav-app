using MolBhav.Domain.Common.Abstractions;

namespace MolBhav.Domain.Common.Primitives;

/// <summary>Base record for domain events. Derived records add their own payload properties.</summary>
public abstract record DomainEvent : IDomainEvent
{
    protected DomainEvent()
        : this(Guid.CreateVersion7(), DateTimeOffset.UtcNow)
    {
    }

    protected DomainEvent(Guid eventId, DateTimeOffset occurredAtUtc)
    {
        EventId = eventId;
        OccurredAtUtc = occurredAtUtc;
    }

    public Guid EventId { get; init; }

    public DateTimeOffset OccurredAtUtc { get; init; }
}
