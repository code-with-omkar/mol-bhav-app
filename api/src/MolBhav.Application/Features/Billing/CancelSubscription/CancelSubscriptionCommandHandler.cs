using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Billing.CancelSubscription;

internal sealed class CancelSubscriptionCommandHandler(
    ISubscriptionRepository subscriptions, IUserRepository users, ICurrentUser currentUser, TimeProvider timeProvider)
    : ICommandHandler<CancelSubscriptionCommand>
{
    public async Task<Result> Handle(CancelSubscriptionCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();

        var subscription = await subscriptions.GetActiveByUserAsync(userId, cancellationToken);
        if (subscription is null)
        {
            return Error.NotFound("Subscription.NotFound", "No active subscription found.");
        }

        var cancelResult = subscription.Cancel(timeProvider.GetUtcNow());
        if (cancelResult.IsFailure)
        {
            return cancelResult;
        }

        var user = await users.GetByIdAsync(userId, cancellationToken);
        user?.SetSubscriptionTier(SubscriptionTier.Free);

        return Result.Success();
    }
}
