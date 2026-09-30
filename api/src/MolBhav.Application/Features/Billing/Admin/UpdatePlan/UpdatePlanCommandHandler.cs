using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Admin.UpdatePlan;

internal sealed class UpdatePlanCommandHandler(IPlanRepository plans) : ICommandHandler<UpdatePlanCommand>
{
    public async Task<Result> Handle(UpdatePlanCommand request, CancellationToken cancellationToken)
    {
        var plan = await plans.GetByIdAsync(request.PlanId, cancellationToken);
        if (plan is null)
        {
            return Error.NotFound("Plan.NotFound", "Plan not found.");
        }

        return plan.Update(request.Name, request.Price!.Value, request.IsActive!.Value);
    }
}
