using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Billing;

namespace MolBhav.Application.Features.Billing.Admin.GetAdminSubscriptions;

public sealed record GetAdminSubscriptionsQuery(Guid? UserId, SubscriptionStatus? Status, int Page, int PageSize)
    : IQuery<PagedResult<AdminSubscriptionResponse>>;
