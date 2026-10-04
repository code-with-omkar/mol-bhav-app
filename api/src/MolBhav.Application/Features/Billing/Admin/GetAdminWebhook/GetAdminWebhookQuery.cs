using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;

namespace MolBhav.Application.Features.Billing.Admin.GetAdminWebhook;

public sealed record GetAdminWebhookQuery(Guid Id) : IQuery<AdminWebhookDetailResponse>;
