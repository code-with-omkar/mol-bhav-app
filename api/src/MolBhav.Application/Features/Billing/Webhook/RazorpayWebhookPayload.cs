using System.Text.Json;

namespace MolBhav.Application.Features.Billing.Webhook;

/// <summary>
/// Reads the fields this integration acts on from a Razorpay webhook body. Shared by the receiving side (event type for
/// the inbox row) and the inbox processor (the command to apply), so both read the payload the same way.
/// </summary>
public static class RazorpayWebhookPayload
{
    public const string Provider = "razorpay";

    /// <summary>
    /// Order and payment ids come from <c>payload.payment.entity</c>, falling back to <c>payload.order.entity.id</c>.
    /// </summary>
    /// <returns><c>false</c> if the body is not JSON or has no <c>event</c>.</returns>
    public static bool TryParse(string rawBody, out HandleRazorpayWebhookCommand command)
    {
        command = null!;

        if (string.IsNullOrWhiteSpace(rawBody))
        {
            return false;
        }

        try
        {
            using var doc = JsonDocument.Parse(rawBody);
            var root = doc.RootElement;
            if (root.ValueKind != JsonValueKind.Object
                || !root.TryGetProperty("event", out var eventProp)
                || eventProp.ValueKind != JsonValueKind.String
                || eventProp.GetString() is not { Length: > 0 } eventType)
            {
                return false;
            }

            string? orderId = null, paymentId = null;
            if (root.TryGetProperty("payload", out var payload) && payload.ValueKind == JsonValueKind.Object)
            {
                if (payload.TryGetProperty("payment", out var payment) && payment.ValueKind == JsonValueKind.Object
                    && payment.TryGetProperty("entity", out var p) && p.ValueKind == JsonValueKind.Object)
                {
                    orderId = StringOrNull(p, "order_id");
                    paymentId = StringOrNull(p, "id");
                }

                if (orderId is null
                    && payload.TryGetProperty("order", out var order) && order.ValueKind == JsonValueKind.Object
                    && order.TryGetProperty("entity", out var o) && o.ValueKind == JsonValueKind.Object)
                {
                    orderId = StringOrNull(o, "id");
                }
            }

            command = new HandleRazorpayWebhookCommand(eventType, orderId, paymentId);
            return true;
        }
        catch (JsonException)
        {
            return false;
        }
    }

    private static string? StringOrNull(JsonElement element, string name) =>
        element.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String ? value.GetString() : null;
}
