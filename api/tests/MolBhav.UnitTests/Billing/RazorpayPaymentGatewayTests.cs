using System.Net;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Billing;
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

    [Fact]
    public async Task GetOrderPaymentsAsync_ParsesTheCollection()
    {
        var handler = new StubHttpHandler(HttpStatusCode.OK, """
            { "entity": "collection", "count": 2, "items": [
              { "id": "pay_1", "entity": "payment", "amount": 49900, "currency": "INR", "status": "failed", "order_id": "order_1", "captured": false },
              { "id": "pay_2", "entity": "payment", "amount": 49900, "currency": "INR", "status": "captured", "order_id": "order_1", "captured": true }
            ] }
            """);

        var result = await GatewayWith(handler).GetOrderPaymentsAsync("order_1");

        Assert.True(result.IsSuccess);
        Assert.Equal(
            new[] { new GatewayPayment("pay_1", 49_900, "INR", "failed"), new GatewayPayment("pay_2", 49_900, "INR", "captured") },
            result.Payments);
        Assert.True(result.Payments[1].IsCaptured);
        Assert.Equal("/v1/orders/order_1/payments", handler.LastRequest!.RequestUri!.AbsolutePath);
        Assert.Equal(HttpMethod.Get, handler.LastRequest.Method);
        Assert.Equal("Basic", handler.LastRequest.Headers.Authorization!.Scheme);
    }

    [Fact]
    public async Task GetOrderPaymentsAsync_ErrorStatus_Fails()
    {
        var result = await GatewayWith(new StubHttpHandler(HttpStatusCode.BadRequest, "{}")).GetOrderPaymentsAsync("order_1");

        Assert.False(result.IsSuccess);
        Assert.Empty(result.Payments);
    }

    [Fact]
    public async Task GetOrderPaymentsAsync_UnexpectedBody_Fails()
    {
        var result = await GatewayWith(new StubHttpHandler(HttpStatusCode.OK, """{ "unexpected": true }""")).GetOrderPaymentsAsync("order_1");

        Assert.False(result.IsSuccess);
    }

    private static RazorpayPaymentGateway GatewayWith(HttpMessageHandler handler)
    {
        var factory = Substitute.For<IHttpClientFactory>();
        factory.CreateClient(RazorpayPaymentGateway.HttpClientName)
            .Returns(_ => new HttpClient(handler, disposeHandler: false) { BaseAddress = new Uri("https://api.razorpay.com") });

        return new RazorpayPaymentGateway(
            factory,
            Options.Create(new RazorpayOptions { KeyId = "rzp_test_key", KeySecret = KeySecret, WebhookSecret = WebhookSecret }),
            NullLogger<RazorpayPaymentGateway>.Instance);
    }

    private sealed class StubHttpHandler(HttpStatusCode status, string body) : HttpMessageHandler
    {
        public HttpRequestMessage? LastRequest { get; private set; }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            LastRequest = request;
            return Task.FromResult(new HttpResponseMessage(status) { Content = new StringContent(body) });
        }
    }
}
