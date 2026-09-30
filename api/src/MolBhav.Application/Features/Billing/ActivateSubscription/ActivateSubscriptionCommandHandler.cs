using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Activation;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.ActivateSubscription;

/// <summary>
/// Checkout step 2, from the client: proves the payment with the checkout signature and activates. Idempotent, and
/// safe to race with the webhook.
/// </summary>
internal sealed class ActivateSubscriptionCommandHandler(
    ISubscriptionRepository subscriptions,
    IPlanRepository plans,
    IPaymentGateway paymentGateway,
    SubscriptionActivationService activation,
    ICurrentUser currentUser) : ICommandHandler<ActivateSubscriptionCommand, SubscriptionResponse>
{
    public async Task<Result<SubscriptionResponse>> Handle(ActivateSubscriptionCommand request, CancellationToken cancellationToken)
    {
        var subscription = await subscriptions.GetByGatewayOrderIdAsync(request.RazorpayOrderId, cancellationToken);

        // Same answer for "no such order" and "someone else's order", so order ids can't be probed.
        if (subscription is null || subscription.UserId != currentUser.GetRequiredUserId())
        {
            return BillingErrors.SubscriptionNotFound;
        }

        if (!paymentGateway.VerifyCheckoutSignature(request.RazorpayOrderId, request.RazorpayPaymentId, request.RazorpaySignature))
        {
            return BillingErrors.InvalidSignature;
        }

        var activated = await activation.ActivateAsync(
            subscription, request.RazorpayPaymentId, request.RazorpaySignature, cancellationToken);
        if (activated.IsFailure)
        {
            return Result.Failure<SubscriptionResponse>(activated.Error);
        }

        var plan = await plans.GetByIdAsync(subscription.PlanId, cancellationToken);

        return new SubscriptionResponse(
            subscription.Id, subscription.PlanId, plan?.Code ?? string.Empty, plan?.Name ?? string.Empty,
            subscription.Status, subscription.BillingCycle, subscription.StartedAtUtc, subscription.ExpiresAtUtc,
            subscription.IsAutoRenew, subscription.CancelledAtUtc);
    }
}
