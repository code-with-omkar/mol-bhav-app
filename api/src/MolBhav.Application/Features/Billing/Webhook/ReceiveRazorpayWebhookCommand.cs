using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.Webhook;

/// <summary>An already-authenticated Razorpay webhook delivery, to be recorded in the inbox (not applied here).</summary>
/// <param name="EventId">The <c>x-razorpay-event-id</c> header — unique per event, repeated on redeliveries.</param>
/// <param name="RawBody">The request body exactly as signed.</param>
public sealed record ReceiveRazorpayWebhookCommand(string EventId, string RawBody) : ICommand;
