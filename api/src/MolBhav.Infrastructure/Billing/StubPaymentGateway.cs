using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Billing;

namespace MolBhav.Infrastructure.Billing;

/// <summary>
/// Development-only stand-in when no Razorpay keys are configured: every order succeeds and every signature
/// verifies. Registration fails at startup outside Development, so it can never serve a paying customer.
/// </summary>
internal sealed partial class StubPaymentGateway(ILogger<StubPaymentGateway> logger) : IPaymentGateway
{
    public string PublicKeyId => string.Empty;

    public bool IsStub => true;

    public Task<CreateOrderResult> CreateOrderAsync(CreateOrderRequest request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var orderId = $"stub_{Guid.CreateVersion7():N}";
        LogOrder(logger, request.SubscriptionId, request.AmountPaise, request.Currency, orderId);
        return Task.FromResult(new CreateOrderResult(orderId, request.AmountPaise, request.Currency, true, null));
    }

    public bool VerifyCheckoutSignature(string orderId, string paymentId, string signature)
    {
        LogVerify(logger, orderId, paymentId);
        return true;
    }

    public bool VerifyWebhookSignature(string rawBody, string signatureHeader) => true;

    [LoggerMessage(Level = LogLevel.Warning,
        Message = "[STUB PAYMENT] Order for subscription {SubscriptionId}: {AmountPaise} {Currency} → {OrderId} (no real gateway configured)")]
    private static partial void LogOrder(ILogger logger, Guid subscriptionId, long amountPaise, string currency, string orderId);

    [LoggerMessage(Level = LogLevel.Warning,
        Message = "[STUB PAYMENT] Accepted payment {PaymentId} for order {OrderId} without verification (no real gateway configured)")]
    private static partial void LogVerify(ILogger logger, string orderId, string paymentId);
}
