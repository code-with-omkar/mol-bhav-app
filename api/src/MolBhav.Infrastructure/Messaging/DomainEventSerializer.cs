using System.Reflection;
using System.Text.Json;
using MolBhav.Domain.Common.Abstractions;

namespace MolBhav.Infrastructure.Messaging;

/// <summary>
/// Outbox (de)serialisation. Types are resolved only from the Domain assembly and must implement
/// <see cref="IDomainEvent"/> — a tampered row can never instantiate an arbitrary type.
/// </summary>
internal static class DomainEventSerializer
{
    private static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web);
    private static readonly Assembly DomainAssembly = typeof(IDomainEvent).Assembly;

    public static string GetTypeName(IDomainEvent domainEvent) =>
        domainEvent.GetType().FullName
        ?? throw new InvalidOperationException("Domain event types must be named, non-generic types.");

    public static string Serialize(IDomainEvent domainEvent) =>
        JsonSerializer.Serialize(domainEvent, domainEvent.GetType(), Options);

    public static IDomainEvent Deserialize(string typeName, string content)
    {
        var type = DomainAssembly.GetType(typeName, throwOnError: false, ignoreCase: false);

        if (type is null || type.IsAbstract || !typeof(IDomainEvent).IsAssignableFrom(type))
        {
            throw new InvalidOperationException($"'{typeName}' is not a known domain event type.");
        }

        return JsonSerializer.Deserialize(content, type, Options) as IDomainEvent
            ?? throw new InvalidOperationException($"Outbox content for '{typeName}' deserialised to null.");
    }
}
