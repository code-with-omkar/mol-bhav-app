using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.GetMySubscription;

internal sealed class GetMySubscriptionQueryHandler(IBillingReadService readService, ICurrentUser currentUser)
    : IQueryHandler<GetMySubscriptionQuery, SubscriptionResponse>
{
    public async Task<Result<SubscriptionResponse>> Handle(GetMySubscriptionQuery request, CancellationToken cancellationToken)
    {
        var subscription = await readService.GetMySubscriptionAsync(currentUser.GetRequiredUserId(), cancellationToken);
        return subscription is null ? Error.NotFound("Subscription.NotFound", "No subscription found.") : subscription;
    }
}
