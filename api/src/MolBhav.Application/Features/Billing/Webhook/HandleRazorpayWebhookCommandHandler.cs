using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Activation;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Webhook;

/// <summary>
/// Orders-API events only: <c>payment.captured</c> and <c>order.paid</c> activate (Razorpay may send either or both),
/// <c>payment.failed</c> is logged, anything else is ignored. Events for unknown orders succeed so Razorpay stops
/// retrying them; replays are no-ops because activation is idempotent.
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
            return Result.Success();
        }

        return await activation.ActivateAsync(subscription, request.PaymentId, signature: null, cancellationToken);
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay payment failed: order {OrderId}, payment {PaymentId}.")]
    private static partial void LogPaymentFailed(ILogger logger, string? orderId, string? paymentId);

    [LoggerMessage(Level = LogLevel.Debug, Message = "Razorpay webhook event {EventType} ignored.")]
    private static partial void LogIgnored(ILogger logger, string eventType);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay {EventType} webhook without order or payment id; ignored.")]
    private static partial void LogMissingIds(ILogger logger, string eventType);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay {EventType} webhook for unknown order {OrderId}; ignored.")]
    private static partial void LogUnknownOrder(ILogger logger, string eventType, string orderId);
}
