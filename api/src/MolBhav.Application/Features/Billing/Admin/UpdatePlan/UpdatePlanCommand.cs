using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.Admin.UpdatePlan;

/// <summary>The code is immutable — subscriptions reference the plan by id, not code, but changing it after
/// customers have subscribed would be confusing in billing history.</summary>
public sealed record UpdatePlanCommand(Guid PlanId, string? Name, decimal? Price, bool? IsActive) : ICommand;
