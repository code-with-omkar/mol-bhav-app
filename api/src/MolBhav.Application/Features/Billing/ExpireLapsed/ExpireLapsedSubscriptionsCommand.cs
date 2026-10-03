using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.ExpireLapsed;

/// <summary>System command, sent by the expiry worker; not exposed over HTTP. Returns how many subscriptions were expired.</summary>
public sealed record ExpireLapsedSubscriptionsCommand(int BatchSize) : ICommand<int>;
