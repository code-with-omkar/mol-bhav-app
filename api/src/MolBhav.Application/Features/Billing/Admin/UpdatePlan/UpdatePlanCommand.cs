using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.Admin.UpdatePlan;

/// <summary>The code is immutable — subscriptions reference the plan by id, not code, but changing it after
/// customers have subscribed would be confusing in billing history.</summary>
public sealed record UpdatePlanCommand(Guid PlanId, string? Name, decimal? Price, bool? IsActive) : ICommand, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Plan.Update";

    string? IAuditedCommand.AuditTarget => PlanId.ToString();

    // The price is business data worth keeping in the log: it changes what customers are charged.
    string IAuditedCommand.AuditSummary =>
        $"Edited a plan (price {Price}, {(IsActive == false ? "switched off" : "on")})";
}
