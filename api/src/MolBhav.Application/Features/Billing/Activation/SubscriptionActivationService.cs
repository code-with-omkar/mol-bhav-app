using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Billing.Activation;

/// <summary>
/// The one path from "payment confirmed" to "user is Pro", shared by the client activate call and the webhook so
/// whichever arrives second is a no-op. Runs inside the caller's unit of work: the status change, the coupon use and
/// the tier flip commit together or not at all.
/// </summary>
internal sealed partial class SubscriptionActivationService(
    ISubscriptionRepository subscriptions,
    ICouponRepository coupons,
    IUserRepository users,
    TimeProvider timeProvider,
    ILogger<SubscriptionActivationService> logger)
{
    public async Task<Result> ActivateAsync(Subscription subscription, string paymentId, string? signature, CancellationToken cancellationToken)
    {
        if (subscription.Status == SubscriptionStatus.Active)
        {
            return subscription.Activate(paymentId, signature, timeProvider.GetUtcNow());
        }

        // An early renewal: the new period continues from the current one, which is then superseded.
        var current = await subscriptions.GetActiveByUserAsync(subscription.UserId, cancellationToken);

        var activated = subscription.Activate(paymentId, signature, timeProvider.GetUtcNow(), current?.ExpiresAtUtc);
        if (activated.IsFailure)
        {
            return activated;
        }

        current?.Expire();

        if (subscription.CouponCode is { } couponCode
            && await coupons.TryIncrementUsageAsync(couponCode, cancellationToken) == 0)
        {
            // The money is already taken, so the subscription must still activate; this only means the coupon was
            // over-redeemed by a race between validation and payment.
            LogCouponCapExceeded(logger, couponCode, subscription.Id);
        }

        var user = await users.GetByIdAsync(subscription.UserId, cancellationToken);
        user?.SetSubscriptionTier(SubscriptionTier.Pro);

        LogActivated(logger, subscription.Id, subscription.RazorpayOrderId);
        return Result.Success();
    }

    [LoggerMessage(Level = LogLevel.Error, Message = "Coupon {CouponCode} reached its usage cap before subscription {SubscriptionId} activated; activated anyway.")]
    private static partial void LogCouponCapExceeded(ILogger logger, string couponCode, Guid subscriptionId);

    [LoggerMessage(Level = LogLevel.Information, Message = "Subscription {SubscriptionId} activated for order {OrderId}.")]
    private static partial void LogActivated(ILogger logger, Guid subscriptionId, string? orderId);
}
