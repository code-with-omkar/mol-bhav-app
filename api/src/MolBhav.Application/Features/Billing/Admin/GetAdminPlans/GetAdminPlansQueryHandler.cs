using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Admin.GetAdminPlans;

internal sealed class GetAdminPlansQueryHandler(IBillingReadService readService) : IQueryHandler<GetAdminPlansQuery, IReadOnlyList<AdminPlanResponse>>
{
    public async Task<Result<IReadOnlyList<AdminPlanResponse>>> Handle(GetAdminPlansQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminPlansAsync(cancellationToken));
}
