using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.Admin.ExpireSubscription;

public sealed record ExpireSubscriptionCommand(Guid SubscriptionId) : ICommand;
