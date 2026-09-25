using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Identity.Events;

/// <summary>
/// Raised the first time a phone number completes OTP verification. Consumed later by the Notification module
/// (welcome message) and Watchlist/Catalog bootstrap handlers once those modules exist — carries no PII beyond
/// the id and the masked phone number, since the outbox payload is persisted (even if briefly).
/// </summary>
public sealed record UserRegisteredDomainEvent(Guid UserId, string PhoneNumberMasked) : DomainEvent;
