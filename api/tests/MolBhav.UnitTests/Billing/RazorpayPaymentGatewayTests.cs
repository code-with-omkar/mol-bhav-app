using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using MolBhav.Infrastructure.Billing.Razorpay;

namespace MolBhav.UnitTests.Billing;

public sealed class RazorpayPaymentGatewayTests
{
    private const string KeySecret = "key_secret_test";
    private const string WebhookSecret = "webhook_secret_test";

    private readonly RazorpayPaymentGateway _gateway = new(
        Substitute.For<IHttpClientFactory>(),
        Options.Create(new RazorpayOptions { KeyId = "rzp_test_key", KeySecret = KeySecret, WebhookSecret = WebhookSecret }),
        NullLogger<RazorpayPaymentGateway>.Instance);

    private static string Hmac(string secret, string payload) =>
        Convert.ToHexStringLower(HMACSHA256.HashData(Encoding.UTF8.GetBytes(secret), Encoding.UTF8.GetBytes(payload)));

    [Fact]
    public void VerifyCheckoutSignature_Valid_IsTrue()
    {
        var signature = Hmac(KeySecret, "order_1|pay_1");

        Assert.True(_gateway.VerifyCheckoutSignature("order_1", "pay_1", signature));
    }

    [Fact]
    public void VerifyCheckoutSignature_SignedForAnotherPayment_IsFalse()
    {
        var signature = Hmac(KeySecret, "order_1|pay_OTHER");

        Assert.False(_gateway.VerifyCheckoutSignature("order_1", "pay_1", signature));
    }

    [Fact]
    public void VerifyCheckoutSignature_SignedWithWebhookSecret_IsFalse()
    {
        var signature = Hmac(WebhookSecret, "order_1|pay_1");

        Assert.False(_gateway.VerifyCheckoutSignature("order_1", "pay_1", signature));
    }

    [Theory]
    [InlineData("")]
    [InlineData(null)]
    public void VerifyCheckoutSignature_Empty_IsFalse(string? signature)
    {
        Assert.False(_gateway.VerifyCheckoutSignature("order_1", "pay_1", signature!));
    }

    [Fact]
    public void VerifyWebhookSignature_Valid_IsTrue()
    {
        const string body = """{"event":"payment.captured"}""";

        Assert.True(_gateway.VerifyWebhookSignature(body, Hmac(WebhookSecret, body)));
    }

    [Fact]
    public void VerifyWebhookSignature_TamperedBody_IsFalse()
    {
        const string body = """{"event":"payment.captured"}""";
        var signature = Hmac(WebhookSecret, body);

        Assert.False(_gateway.VerifyWebhookSignature(body.Replace("captured", "failed", StringComparison.Ordinal), signature));
    }

    [Fact]
    public void VerifyWebhookSignature_MissingHeader_IsFalse()
    {
        Assert.False(_gateway.VerifyWebhookSignature("""{"event":"payment.captured"}""", string.Empty));
    }
}
