using System.Collections.Concurrent;
using Microsoft.Extensions.DependencyInjection;
using MolBhav.Application.Abstractions.Events;
using MolBhav.Domain.Common.Abstractions;

namespace MolBhav.Infrastructure.Messaging;

/// <summary>Resolves and invokes every <see cref="IDomainEventHandler{TEvent}"/> for an event's runtime type (no reflection per call after warm-up).</summary>
internal sealed class DomainEventDispatcher(IServiceProvider serviceProvider)
{
    private static readonly ConcurrentDictionary<Type, HandlerInvoker> Invokers = new();

    public Task DispatchAsync(IDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(domainEvent);

        var invoker = Invokers.GetOrAdd(
            domainEvent.GetType(),
            static eventType => (HandlerInvoker)Activator.CreateInstance(typeof(HandlerInvoker<>).MakeGenericType(eventType))!);

        return invoker.InvokeAsync(serviceProvider, domainEvent, cancellationToken);
    }

    private abstract class HandlerInvoker
    {
        public abstract Task InvokeAsync(IServiceProvider serviceProvider, IDomainEvent domainEvent, CancellationToken cancellationToken);
    }

    private sealed class HandlerInvoker<TEvent> : HandlerInvoker
        where TEvent : IDomainEvent
    {
        public override async Task InvokeAsync(IServiceProvider serviceProvider, IDomainEvent domainEvent, CancellationToken cancellationToken)
        {
            foreach (var handler in serviceProvider.GetServices<IDomainEventHandler<TEvent>>())
            {
                await handler.HandleAsync((TEvent)domainEvent, cancellationToken);
            }
        }
    }
}
