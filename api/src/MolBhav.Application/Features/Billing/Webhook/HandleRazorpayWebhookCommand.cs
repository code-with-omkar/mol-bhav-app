using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.Webhook;

/// <summary>An already-authenticated Razorpay webhook event, reduced to the fields this integration acts on.</summary>
/// <param name="EventType">Razorpay event name, e.g. <c>payment.captured</c>.</param>
/// <param name="OrderId">Razorpay order the payment belongs to; identifies the subscription.</param>
/// <param name="PaymentId">Razorpay payment id; recorded on the subscription when it activates.</param>
/// <param name="AmountPaise">Payment amount in paise; checked against the subscription's charge before activating.</param>
/// <param name="Currency">Payment currency; checked together with the amount.</param>
public sealed record HandleRazorpayWebhookCommand(
    string EventType,
    string? OrderId,
    string? PaymentId,
    long? AmountPaise,
    string? Currency) : ICommand;
