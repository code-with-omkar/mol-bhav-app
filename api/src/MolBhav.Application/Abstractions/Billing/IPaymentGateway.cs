namespace MolBhav.Application.Abstractions.Billing;

/// <summary>
/// The payment gateway: Razorpay Orders API, or a stub in Development when no credentials are configured.
/// The two signature checks are different proofs with different secrets: the checkout signature is what the
/// client received from the SDK (HMAC of <c>orderId|paymentId</c> with the key secret); the webhook signature
/// authenticates the raw webhook body (HMAC with the webhook secret).
/// </summary>
public interface IPaymentGateway
{
    /// <summary>Public key the mobile SDK opens checkout with; empty for the stub.</summary>
    string PublicKeyId { get; }

    bool IsStub { get; }

    Task<CreateOrderResult> CreateOrderAsync(CreateOrderRequest request, CancellationToken ct = default);

    bool VerifyCheckoutSignature(string orderId, string paymentId, string signature);

    bool VerifyWebhookSignature(string rawBody, string signatureHeader);
}

public sealed record CreateOrderRequest(Guid SubscriptionId, string PlanCode, long AmountPaise, string Currency, string? CouponCode);

public sealed record CreateOrderResult(string GatewayOrderId, long AmountPaise, string Currency, bool IsSuccess, string? ErrorMessage)
{
    public static CreateOrderResult Failed(CreateOrderRequest request, string error) =>
        new(string.Empty, request.AmountPaise, request.Currency, false, error);
}
