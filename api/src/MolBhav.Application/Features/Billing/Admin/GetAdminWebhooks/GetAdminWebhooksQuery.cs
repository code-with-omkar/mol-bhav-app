using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Billing.Models;

namespace MolBhav.Application.Features.Billing.Admin.GetAdminWebhooks;

public sealed record GetAdminWebhooksQuery(WebhookInboxState? State, string? EventType, int Page, int PageSize)
    : IQuery<PagedResult<AdminWebhookResponse>>;
