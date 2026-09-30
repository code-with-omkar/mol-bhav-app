using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Admin.CreatePlan;

internal sealed class CreatePlanCommandHandler(IPlanRepository plans) : ICommandHandler<CreatePlanCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreatePlanCommand request, CancellationToken cancellationToken)
    {
        if (await plans.CodeExistsAsync(request.Code!.Trim(), cancellationToken))
        {
            return Error.Conflict("Plan.CodeAlreadyExists", "A plan with this code already exists.");
        }

        var plan = Plan.Create(request.Code, request.Name, request.Price!.Value, request.Currency, request.BillingPeriod!.Value);
        if (plan.IsFailure)
        {
            return Result.Failure<CreatedResponse>(plan.Error);
        }

        plans.Add(plan.Value);
        return new CreatedResponse(plan.Value.Id);
    }
}
