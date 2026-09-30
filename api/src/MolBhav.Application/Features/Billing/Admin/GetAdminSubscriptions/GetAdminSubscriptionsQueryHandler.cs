using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Admin.GetAdminSubscriptions;

internal sealed class GetAdminSubscriptionsQueryHandler(IBillingReadService readService)
    : IQueryHandler<GetAdminSubscriptionsQuery, PagedResult<AdminSubscriptionResponse>>
{
    public async Task<Result<PagedResult<AdminSubscriptionResponse>>> Handle(GetAdminSubscriptionsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminSubscriptionsAsync(
            new AdminSubscriptionFilter(request.UserId, request.Status, new PageRequest(request.Page, request.PageSize)),
            cancellationToken));
}
