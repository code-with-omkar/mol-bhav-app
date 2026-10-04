using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Activation;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.ReconcilePayments;

/// <summary>
/// Activates a pending subscription from the gateway's own record of its order, through the same
/// <see cref="SubscriptionActivationService"/> as the client callback and the webhook — so whichever path comes second
/// is a no-op, and a webhook processed later for the same payment just succeeds.
/// <para>
/// Only a <c>captured</c> payment for exactly the subscription's charge activates. A gateway failure is returned as
/// <see cref="BillingErrors.GatewayUnavailable"/> (nothing changes; the next sweep retries). An activation here means a
/// webhook was missed and is logged at Warning; a captured payment that doesn't match, or more than one captured
/// payment for the order, is logged at Critical because someone was charged and needs a refund.
/// </para>
/// </summary>
internal sealed partial class ReconcilePendingPaymentCommandHandler(
    ISubscriptionRepository subscriptions,
    IPaymentGateway paymentGateway,
    SubscriptionActivationService activation,
    ILogger<ReconcilePendingPaymentCommandHandler> logger)
    : ICommandHandler<ReconcilePendingPaymentCommand, PaymentReconciliationOutcome>
{
    public async Task<Result<PaymentReconciliationOutcome>> Handle(ReconcilePendingPaymentCommand request, CancellationToken cancellationToken)
    {
        var subscription = await subscriptions.GetByIdAsync(request.SubscriptionId, cancellationToken);
        if (subscription is null
            || subscription.Status != SubscriptionStatus.PendingPayment
            || subscription.RazorpayOrderId is not { } orderId)
        {
            return PaymentReconciliationOutcome.NotPending;
        }

        var lookup = await paymentGateway.GetOrderPaymentsAsync(orderId, cancellationToken);
        if (!lookup.IsSuccess)
        {
            return BillingErrors.GatewayUnavailable;
        }

        var captured = lookup.Payments.Where(p => p.IsCaptured).ToList();
        if (captured.Count == 0)
        {
            return PaymentReconciliationOutcome.NoCapturedPayment;
        }

        if (captured.Count > 1)
        {
            LogMultipleCaptured(logger, orderId, subscription.Id, captured.Count);
        }

        var payment = captured.Find(p => subscription.IsChargedBy(p.AmountPaise, p.Currency));
        if (payment is null)
        {
            LogAmountMismatch(logger, orderId, subscription.Id, captured[0].PaymentId, captured[0].AmountPaise, captured[0].Currency, subscription.ChargePaise, subscription.Currency);
            return PaymentReconciliationOutcome.AmountMismatch;
        }

        var activated = await activation.ActivateAsync(subscription, payment.PaymentId, signature: null, cancellationToken);
        if (activated.IsFailure)
        {
            return Result.Failure<PaymentReconciliationOutcome>(activated.Error);
        }

        LogActivatedByReconciliation(logger, subscription.Id, orderId, payment.PaymentId);
        return PaymentReconciliationOutcome.Activated;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Subscription {SubscriptionId} activated by reconciliation from order {OrderId}, payment {PaymentId}: its payment webhook was never applied.")]
    private static partial void LogActivatedByReconciliation(ILogger logger, Guid subscriptionId, string orderId, string paymentId);

    [LoggerMessage(Level = LogLevel.Critical, Message = "Order {OrderId} (subscription {SubscriptionId}) has {Count} captured payments; all but one need a refund.")]
    private static partial void LogMultipleCaptured(ILogger logger, string orderId, Guid subscriptionId, int count);

    [LoggerMessage(Level = LogLevel.Critical, Message = "Order {OrderId} (subscription {SubscriptionId}): captured payment {PaymentId} of {PaidPaise} {PaidCurrency} does not match the charge of {ChargePaise} {Currency}; not activated, needs review.")]
    private static partial void LogAmountMismatch(
        ILogger logger, string orderId, Guid subscriptionId, string paymentId, long paidPaise, string paidCurrency, long chargePaise, string currency);
}
