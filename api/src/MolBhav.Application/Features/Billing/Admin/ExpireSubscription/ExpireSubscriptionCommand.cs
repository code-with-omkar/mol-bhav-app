using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.Admin.ExpireSubscription;

public sealed record ExpireSubscriptionCommand(Guid SubscriptionId) : ICommand, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Subscription.Expire";

    string? IAuditedCommand.AuditTarget => SubscriptionId.ToString();

    string IAuditedCommand.AuditSummary => "Ended a subscription early";
}
