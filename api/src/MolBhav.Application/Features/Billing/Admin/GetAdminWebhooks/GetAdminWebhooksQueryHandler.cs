using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Admin.GetAdminWebhooks;

internal sealed class GetAdminWebhooksQueryHandler(IBillingReadService readService)
    : IQueryHandler<GetAdminWebhooksQuery, PagedResult<AdminWebhookResponse>>
{
    public async Task<Result<PagedResult<AdminWebhookResponse>>> Handle(GetAdminWebhooksQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminWebhooksAsync(
            new AdminWebhookFilter(request.State, request.EventType, new PageRequest(request.Page, request.PageSize)),
            cancellationToken));
}
