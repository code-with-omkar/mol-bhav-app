using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using MolBhav.Domain.Common.Abstractions;
using MolBhav.Infrastructure.Messaging;
using MolBhav.Infrastructure.Messaging.Outbox;

namespace MolBhav.Infrastructure.Persistence.Interceptors;

/// <summary>
/// Moves raised domain events into outbox rows inside the same SaveChanges (same transaction).
/// Events are cleared from the aggregate once they are tracked as outbox rows, so a retried SaveChanges
/// on the same context persists them exactly once.
/// </summary>
internal sealed class DomainEventsToOutboxInterceptor : SaveChangesInterceptor
{
    public override InterceptionResult<int> SavingChanges(DbContextEventData eventData, InterceptionResult<int> result)
    {
        Apply(eventData.Context);
        return base.SavingChanges(eventData, result);
    }

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        Apply(eventData.Context);
        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    private static void Apply(DbContext? context)
    {
        if (context is null)
        {
            return;
        }

        var aggregates = context.ChangeTracker
            .Entries<IHasDomainEvents>()
            .Select(entry => entry.Entity)
            .Where(aggregate => aggregate.DomainEvents.Count != 0)
            .ToList();

        if (aggregates.Count == 0)
        {
            return;
        }

        var messages = new List<OutboxMessage>();

        foreach (var aggregate in aggregates)
        {
            messages.AddRange(aggregate.DomainEvents.Select(domainEvent => OutboxMessage.Create(
                domainEvent.EventId,
                domainEvent.OccurredAtUtc,
                DomainEventSerializer.GetTypeName(domainEvent),
                DomainEventSerializer.Serialize(domainEvent))));

            aggregate.ClearDomainEvents();
        }

        context.Set<OutboxMessage>().AddRange(messages);
    }
}
