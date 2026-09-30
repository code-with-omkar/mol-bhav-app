using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.Webhook;

/// <summary>An already-authenticated Razorpay webhook event, reduced to the fields this integration acts on.</summary>
public sealed record HandleRazorpayWebhookCommand(string EventType, string? OrderId, string? PaymentId) : ICommand;
