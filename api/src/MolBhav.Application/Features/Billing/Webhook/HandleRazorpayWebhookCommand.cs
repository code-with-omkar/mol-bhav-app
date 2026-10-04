using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.Webhook;

/// <summary>An already-authenticated Razorpay webhook event, reduced to the fields this integration acts on.</summary>
/// <param name="AmountPaise">Payment amount in paise; checked against the subscription's charge before activating.</param>
public sealed record HandleRazorpayWebhookCommand(
    string EventType,
    string? OrderId,
    string? PaymentId,
    long? AmountPaise,
    string? Currency) : ICommand;
