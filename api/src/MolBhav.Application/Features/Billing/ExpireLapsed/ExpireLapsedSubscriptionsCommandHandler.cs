using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Billing.ExpireLapsed;

/// <summary>
/// Ends every paid period that has run out and drops the user back to <see cref="SubscriptionTier.Free"/>, in the same
/// unit of work. Idempotent: an expired row is no longer Active, so a repeated run finds nothing to do.
/// The tier flag is also carried in the JWT, so the downgrade reaches the API gate when the access token is next refreshed.
/// </summary>
internal sealed partial class ExpireLapsedSubscriptionsCommandHandler(
    ISubscriptionRepository subscriptions,
    IUserRepository users,
    TimeProvider timeProvider,
    ILogger<ExpireLapsedSubscriptionsCommandHandler> logger)
    : ICommandHandler<ExpireLapsedSubscriptionsCommand, int>
{
    public async Task<Result<int>> Handle(ExpireLapsedSubscriptionsCommand request, CancellationToken cancellationToken)
    {
        var lapsed = await subscriptions.GetLapsedActiveAsync(timeProvider.GetUtcNow(), request.BatchSize, cancellationToken);

        var expired = 0;
        foreach (var subscription in lapsed)
        {
            if (subscription.Expire().IsFailure)
            {
                continue;
            }

            var user = await users.GetByIdAsync(subscription.UserId, cancellationToken);
            user?.SetSubscriptionTier(SubscriptionTier.Free);

            LogExpired(logger, subscription.Id, subscription.UserId);
            expired++;
        }

        return expired;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Subscription {SubscriptionId} for user {UserId} expired; tier set to Free.")]
    private static partial void LogExpired(ILogger logger, Guid subscriptionId, Guid userId);
}
