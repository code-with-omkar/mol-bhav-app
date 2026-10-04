using MolBhav.Application.Features.Billing.Webhook;

namespace MolBhav.UnitTests.Billing;

public sealed class RazorpayWebhookPayloadTests
{
    [Fact]
    public void TryParse_PaymentCaptured_ReadsIdsAmountAndCurrency()
    {
        const string body = """
            {
              "entity": "event", "account_id": "acc_1", "event": "payment.captured", "contains": ["payment"],
              "payload": { "payment": { "entity": {
                "id": "pay_1", "entity": "payment", "amount": 49900, "currency": "INR", "status": "captured",
                "order_id": "order_1", "method": "upi", "captured": true, "notes": { "subscription_id": "x" }
              } } },
              "created_at": 1759570000
            }
            """;

        Assert.True(RazorpayWebhookPayload.TryParse(body, out var command));

        Assert.Equal(new HandleRazorpayWebhookCommand("payment.captured", "order_1", "pay_1", 49_900, "INR"), command);
    }

    [Fact]
    public void TryParse_OrderPaid_TakesPaymentFieldsAndOrderIdFromPayment()
    {
        const string body = """
            {
              "event": "order.paid",
              "payload": {
                "payment": { "entity": { "id": "pay_2", "amount": 48900, "currency": "INR", "status": "captured", "order_id": "order_2" } },
                "order": { "entity": { "id": "order_2", "amount": 48900, "amount_paid": 48900, "currency": "INR", "status": "paid" } }
              }
            }
            """;

        Assert.True(RazorpayWebhookPayload.TryParse(body, out var command));

        Assert.Equal(new HandleRazorpayWebhookCommand("order.paid", "order_2", "pay_2", 48_900, "INR"), command);
    }

    [Fact]
    public void TryParse_OrderOnly_FallsBackToOrderIdAndAmountPaid()
    {
        const string body = """
            { "event": "order.paid", "payload": { "order": { "entity": { "id": "order_3", "amount_paid": 1000, "currency": "INR" } } } }
            """;

        Assert.True(RazorpayWebhookPayload.TryParse(body, out var command));

        Assert.Equal(new HandleRazorpayWebhookCommand("order.paid", "order_3", null, 1_000, "INR"), command);
    }

    [Fact]
    public void TryParse_UnhandledEventWithOtherEntities_StillReadsTheEventType()
    {
        const string body = """{ "event": "refund.created", "payload": { "refund": { "entity": { "id": "rfnd_1", "amount": 100 } } } }""";

        Assert.True(RazorpayWebhookPayload.TryParse(body, out var command));

        Assert.Equal("refund.created", command.EventType);
        Assert.Null(command.OrderId);
        Assert.Null(command.AmountPaise);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("not json")]
    [InlineData("[]")]
    [InlineData("""{ "payload": {} }""")]
    [InlineData("""{ "event": "" }""")]
    [InlineData("""{ "event": 42 }""")]
    [InlineData("""{ "event": "payment.captured", "payload": { "payment": { "entity": { "amount": "49900" } } } }""")]
    [InlineData("""{ "event": "payment.captured", "payload": { "payment": { "entity": { "amount": 499.5 } } } }""")]
    public void TryParse_Unreadable_ReturnsFalse(string body)
    {
        Assert.False(RazorpayWebhookPayload.TryParse(body, out _));
    }
}
