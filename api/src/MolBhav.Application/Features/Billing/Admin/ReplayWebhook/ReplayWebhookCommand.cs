using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.Admin.ReplayWebhook;

/// <summary>Admin: put a parked webhook back in the inbox queue once its cause is fixed (or confirmed transient).</summary>
public sealed record ReplayWebhookCommand(Guid Id) : ICommand;
