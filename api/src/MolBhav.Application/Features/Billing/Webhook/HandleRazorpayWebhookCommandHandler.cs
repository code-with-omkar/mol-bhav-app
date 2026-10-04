using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Activation;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Webhook;

/// <summary>
/// Applies one webhook from the inbox. Orders-API events only: <c>payment.captured</c> and <c>order.paid</c> activate
/// (Razorpay may send either or both) once the paid amount matches the subscription's charge, <c>payment.failed</c> is
/// logged, anything else is ignored. Replays are no-ops because activation is idempotent.
/// <para>
/// An unknown order fails with <see cref="BillingErrors.SubscriptionNotFound"/> so the inbox retries it: the webhook
/// can arrive before the subscribe request that attached the order has committed. If the order never appears, the
/// message is parked after the configured attempts instead of being silently dropped.
/// </para>
/// </summary>
internal sealed partial class HandleRazorpayWebhookCommandHandler(
    ISubscriptionRepository subscriptions,
    SubscriptionActivationService activation,
    ILogger<HandleRazorpayWebhookCommandHandler> logger) : ICommandHandler<HandleRazorpayWebhookCommand>
{
    public const string PaymentCaptured = "payment.captured";
    public const string OrderPaid = "order.paid";
    public const string PaymentFailed = "payment.failed";

    public async Task<Result> Handle(HandleRazorpayWebhookCommand request, CancellationToken cancellationToken)
    {
        switch (request.EventType)
        {
            case PaymentCaptured or OrderPaid:
                return await ActivateAsync(request, cancellationToken);

            case PaymentFailed:
                LogPaymentFailed(logger, request.OrderId, request.PaymentId);
                return Result.Success();

            default:
                LogIgnored(logger, request.EventType);
                return Result.Success();
        }
    }

    private async Task<Result> ActivateAsync(HandleRazorpayWebhookCommand request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.OrderId) || string.IsNullOrWhiteSpace(request.PaymentId))
        {
            LogMissingIds(logger, request.EventType);
            return Result.Success();
        }

        var subscription = await subscriptions.GetByGatewayOrderIdAsync(request.OrderId, cancellationToken);
        if (subscription is null)
        {
            LogUnknownOrder(logger, request.EventType, request.OrderId);
            return BillingErrors.SubscriptionNotFound;
        }

        // A payment for a different amount (stale price after a checkout retry, tampering, wrong currency) must never
        // activate; the Conflict parks the message for a human, who usually needs to refund it.
        if (request.AmountPaise is not { } paid || !subscription.IsChargedBy(paid, request.Currency))
        {
            LogAmountMismatch(logger, request.EventType, request.OrderId, request.PaymentId, request.AmountPaise, request.Currency, subscription.ChargePaise, subscription.Currency);
            return BillingErrors.PaymentAmountMismatch;
        }

        return await activation.ActivateAsync(subscription, request.PaymentId, signature: null, cancellationToken);
    }

    [LoggerMessage(Level = LogLevel.Error, Message = "Razorpay {EventType} webhook for order {OrderId}, payment {PaymentId}: paid {PaidPaise} {PaidCurrency}, subscription charges {ChargePaise} {Currency}; not activated.")]
    private static partial void LogAmountMismatch(
        ILogger logger, string eventType, string orderId, string paymentId, long? paidPaise, string? paidCurrency, long chargePaise, string currency);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay payment failed: order {OrderId}, payment {PaymentId}.")]
    private static partial void LogPaymentFailed(ILogger logger, string? orderId, string? paymentId);

    [LoggerMessage(Level = LogLevel.Debug, Message = "Razorpay webhook event {EventType} ignored.")]
    private static partial void LogIgnored(ILogger logger, string eventType);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay {EventType} webhook without order or payment id; ignored.")]
    private static partial void LogMissingIds(ILogger logger, string eventType);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay {EventType} webhook for unknown order {OrderId}; will be retried.")]
    private static partial void LogUnknownOrder(ILogger logger, string eventType, string orderId);
}
