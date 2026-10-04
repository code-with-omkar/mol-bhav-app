using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Admin.GetAdminWebhook;

internal sealed class GetAdminWebhookQueryHandler(IBillingReadService readService)
    : IQueryHandler<GetAdminWebhookQuery, AdminWebhookDetailResponse>
{
    public async Task<Result<AdminWebhookDetailResponse>> Handle(GetAdminWebhookQuery request, CancellationToken cancellationToken) =>
        Result.FromNullable(await readService.GetAdminWebhookAsync(request.Id, cancellationToken), BillingErrors.WebhookNotFound);
}
