using System.Globalization;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Billing;

namespace MolBhav.Infrastructure.Billing.Razorpay;

/// <summary>Razorpay Orders API. Never logs secrets or Razorpay's response bodies.</summary>
internal sealed partial class RazorpayPaymentGateway(
    IHttpClientFactory httpClientFactory,
    IOptions<RazorpayOptions> options,
    ILogger<RazorpayPaymentGateway> logger) : IPaymentGateway
{
    public const string HttpClientName = "razorpay";

    /// <summary>Razorpay caps <c>receipt</c> at 40 characters.</summary>
    private const int ReceiptLength = 20;

    private readonly RazorpayOptions _options = options.Value;

    public string PublicKeyId => _options.KeyId;

    public bool IsStub => false;

    public async Task<CreateOrderResult> CreateOrderAsync(CreateOrderRequest request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        using var message = new HttpRequestMessage(HttpMethod.Post, "/v1/orders")
        {
            Content = JsonContent.Create(new
            {
                amount = request.AmountPaise,
                currency = request.Currency,
                receipt = request.SubscriptionId.ToString("N", CultureInfo.InvariantCulture)[..ReceiptLength],
                notes = new { subscription_id = request.SubscriptionId.ToString() },
            }),
        };
        message.Headers.Authorization = BasicAuthorization();

        try
        {
            var client = httpClientFactory.CreateClient(HttpClientName);
            using var response = await client.SendAsync(message, ct);

            if (!response.IsSuccessStatusCode)
            {
                LogOrderRejected(logger, request.SubscriptionId, (int)response.StatusCode);
                return CreateOrderResult.Failed(request, $"Gateway returned {(int)response.StatusCode}.");
            }

            await using var body = await response.Content.ReadAsStreamAsync(ct);
            using var json = await JsonDocument.ParseAsync(body, cancellationToken: ct);
            var root = json.RootElement;

            return new CreateOrderResult(
                root.GetProperty("id").GetString() ?? string.Empty,
                root.GetProperty("amount").GetInt64(),
                root.GetProperty("currency").GetString() ?? request.Currency,
                IsSuccess: true,
                ErrorMessage: null);
        }
        // Network errors, resilience timeouts / open circuit, or an unexpected body: all mean "no order", never a 500.
        catch (Exception ex) when (!ct.IsCancellationRequested)
        {
            LogOrderFailed(logger, request.SubscriptionId, ex.GetType().Name);
            return CreateOrderResult.Failed(request, "Gateway unreachable.");
        }
    }

    public async Task<OrderPaymentsResult> GetOrderPaymentsAsync(string orderId, CancellationToken ct = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(orderId);

        using var message = new HttpRequestMessage(HttpMethod.Get, $"/v1/orders/{Uri.EscapeDataString(orderId)}/payments");
        message.Headers.Authorization = BasicAuthorization();

        try
        {
            var client = httpClientFactory.CreateClient(HttpClientName);
            using var response = await client.SendAsync(message, ct);

            if (!response.IsSuccessStatusCode)
            {
                LogPaymentsRejected(logger, orderId, (int)response.StatusCode);
                return OrderPaymentsResult.Failed($"Gateway returned {(int)response.StatusCode}.");
            }

            // { "entity": "collection", "count": n, "items": [ { "id", "amount", "currency", "status", ... } ] }
            await using var body = await response.Content.ReadAsStreamAsync(ct);
            using var json = await JsonDocument.ParseAsync(body, cancellationToken: ct);

            var payments = new List<GatewayPayment>();
            foreach (var item in json.RootElement.GetProperty("items").EnumerateArray())
            {
                payments.Add(new GatewayPayment(
                    item.GetProperty("id").GetString() ?? string.Empty,
                    item.GetProperty("amount").GetInt64(),
                    item.GetProperty("currency").GetString() ?? string.Empty,
                    item.GetProperty("status").GetString() ?? string.Empty));
            }

            return OrderPaymentsResult.Success(payments);
        }
        // Network errors, resilience timeouts / open circuit, or an unexpected body: "unknown", retried on the next sweep.
        catch (Exception ex) when (!ct.IsCancellationRequested)
        {
            LogPaymentsFailed(logger, orderId, ex.GetType().Name);
            return OrderPaymentsResult.Failed("Gateway unreachable.");
        }
    }

    public bool VerifyCheckoutSignature(string orderId, string paymentId, string signature) =>
        !string.IsNullOrEmpty(orderId)
        && !string.IsNullOrEmpty(paymentId)
        && SignatureMatches(_options.KeySecret, $"{orderId}|{paymentId}", signature);

    public bool VerifyWebhookSignature(string rawBody, string signatureHeader) =>
        !string.IsNullOrEmpty(rawBody) && SignatureMatches(_options.WebhookSecret, rawBody, signatureHeader);

    private AuthenticationHeaderValue BasicAuthorization() =>
        new("Basic", Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_options.KeyId}:{_options.KeySecret}")));

    /// <summary>HMAC-SHA256 → lowercase hex, compared in constant time.</summary>
    internal static bool SignatureMatches(string secret, string payload, string? signature)
    {
        if (string.IsNullOrEmpty(secret) || string.IsNullOrEmpty(signature))
        {
            return false;
        }

        var expected = Convert.ToHexStringLower(
            HMACSHA256.HashData(Encoding.UTF8.GetBytes(secret), Encoding.UTF8.GetBytes(payload)));

        return CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(expected), Encoding.UTF8.GetBytes(signature));
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay rejected the order for subscription {SubscriptionId} with HTTP {StatusCode}.")]
    private static partial void LogOrderRejected(ILogger logger, Guid subscriptionId, int statusCode);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay order for subscription {SubscriptionId} failed: {ErrorType}.")]
    private static partial void LogOrderFailed(ILogger logger, Guid subscriptionId, string errorType);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay rejected the payments lookup for order {OrderId} with HTTP {StatusCode}.")]
    private static partial void LogPaymentsRejected(ILogger logger, string orderId, int statusCode);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay payments lookup for order {OrderId} failed: {ErrorType}.")]
    private static partial void LogPaymentsFailed(ILogger logger, string orderId, string errorType);
}
