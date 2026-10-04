using System.Text.Json;
using System.Text.Json.Serialization;

namespace MolBhav.Application.Features.Billing.Webhook;

/// <summary>
/// Reads a Razorpay webhook body into typed records and reduces it to the command this integration acts on. Shared by
/// the receiving side (event type for the inbox row) and the inbox processor (the command to apply), so both read the
/// payload the same way.
/// <para>
/// Source-generated System.Text.Json: no reflection; unknown properties are ignored, so fields Razorpay adds later can't
/// break parsing; a property of the wrong JSON type (e.g. a string amount) makes the body unreadable rather than
/// silently zero, and unreadable messages are parked for review.
/// </para>
/// </summary>
public static class RazorpayWebhookPayload
{
    public const string Provider = "razorpay";

    /// <summary>
    /// Ids, amount and currency come from <c>payload.payment.entity</c>; order id, amount and currency fall back to
    /// <c>payload.order.entity</c> (an <c>order.paid</c> event carries both).
    /// </summary>
    /// <returns><c>false</c> if the body is not a JSON object with a string <c>event</c>, or a known field has the wrong type.</returns>
    public static bool TryParse(string rawBody, out HandleRazorpayWebhookCommand command)
    {
        command = null!;

        if (string.IsNullOrWhiteSpace(rawBody))
        {
            return false;
        }

        RazorpayWebhookEnvelope? envelope;
        try
        {
            envelope = JsonSerializer.Deserialize(rawBody, RazorpayWebhookJsonContext.Default.RazorpayWebhookEnvelope);
        }
        catch (JsonException)
        {
            return false;
        }

        if (envelope is null || envelope.Event is not { Length: > 0 } eventType)
        {
            return false;
        }

        var payment = envelope.Payload?.Payment?.Entity;
        var order = envelope.Payload?.Order?.Entity;

        command = new HandleRazorpayWebhookCommand(
            EventType: eventType,
            OrderId: NullIfBlank(payment?.OrderId) ?? NullIfBlank(order?.Id),
            PaymentId: NullIfBlank(payment?.Id),
            AmountPaise: payment?.Amount ?? order?.AmountPaid,
            Currency: NullIfBlank(payment?.Currency) ?? NullIfBlank(order?.Currency));
        return true;
    }

    private static string? NullIfBlank(string? value) => string.IsNullOrWhiteSpace(value) ? null : value;
}

/// <summary>Top level of every Razorpay webhook: <c>{ "entity": "event", "event": "...", "payload": { ... } }</c>.</summary>
internal sealed record RazorpayWebhookEnvelope(string? Event, RazorpayWebhookBody? Payload);

internal sealed record RazorpayWebhookBody(RazorpayPaymentWrapper? Payment, RazorpayOrderWrapper? Order);

internal sealed record RazorpayPaymentWrapper(RazorpayPaymentEntity? Entity);

internal sealed record RazorpayOrderWrapper(RazorpayOrderEntity? Entity);

/// <summary>A Razorpay payment. Amounts are integer paise.</summary>
internal sealed record RazorpayPaymentEntity(string? Id, string? OrderId, long? Amount, string? Currency, string? Status);

/// <summary>A Razorpay order. <c>amount_paid</c> is what has been captured against it so far, in paise.</summary>
internal sealed record RazorpayOrderEntity(string? Id, long? Amount, long? AmountPaid, string? Currency, string? Status);

[JsonSourceGenerationOptions(
    PropertyNamingPolicy = JsonKnownNamingPolicy.SnakeCaseLower,
    NumberHandling = JsonNumberHandling.Strict)]
[JsonSerializable(typeof(RazorpayWebhookEnvelope))]
internal sealed partial class RazorpayWebhookJsonContext : JsonSerializerContext
{
}
