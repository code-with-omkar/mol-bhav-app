namespace MolBhav.Domain.Common.Abstractions;

/// <summary>Non-generic view over aggregates so persistence can collect events without knowing the key type.</summary>
public interface IHasDomainEvents
{
    IReadOnlyCollection<IDomainEvent> DomainEvents { get; }

    void ClearDomainEvents();
}
