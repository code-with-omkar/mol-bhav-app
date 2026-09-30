using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Billing.Admin.ExpireSubscription;

internal sealed class ExpireSubscriptionCommandHandler(ISubscriptionRepository subscriptions, IUserRepository users)
    : ICommandHandler<ExpireSubscriptionCommand>
{
    public async Task<Result> Handle(ExpireSubscriptionCommand request, CancellationToken cancellationToken)
    {
        var subscription = await subscriptions.GetByIdAsync(request.SubscriptionId, cancellationToken);
        if (subscription is null)
        {
            return Error.NotFound("Subscription.NotFound", "Subscription not found.");
        }

        var expireResult = subscription.Expire();
        if (expireResult.IsFailure)
        {
            return expireResult;
        }

        var user = await users.GetByIdAsync(subscription.UserId, cancellationToken);
        user?.SetSubscriptionTier(SubscriptionTier.Free);

        return Result.Success();
    }
}
