using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.GetPlans;

internal sealed class GetPlansQueryHandler(IBillingReadService readService) : IQueryHandler<GetPlansQuery, IReadOnlyList<PlanResponse>>
{
    public async Task<Result<IReadOnlyList<PlanResponse>>> Handle(GetPlansQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetActivePlansAsync(cancellationToken));
}
