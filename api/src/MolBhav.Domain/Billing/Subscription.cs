using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Billing;

/// <summary>
/// One user's paid period on a <see cref="Plan"/>. Created in <see cref="SubscriptionStatus.PendingPayment"/> when the
/// gateway order is opened; transitions to <see cref="SubscriptionStatus.Active"/> once the payment is confirmed, by the
/// client (checkout signature) or by the gateway webhook, whichever arrives first.
/// No hard delete: a subscription is billing history and is kept even once cancelled or expired.
/// </summary>
public sealed class Subscription : AggregateRoot<Guid>, IAuditableEntity
{
    public const string DefaultCurrency = "INR";

    private Subscription(Guid id, Guid userId, Guid planId, BillingPeriod billingCycle)
        : base(id)
    {
        UserId = userId;
        PlanId = planId;
        BillingCycle = billingCycle;
        Status = SubscriptionStatus.PendingPayment;
        Currency = DefaultCurrency;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private Subscription()
    {
        Currency = DefaultCurrency;
    }

    public Guid UserId { get; private set; }

    public Guid PlanId { get; private set; }

    public SubscriptionStatus Status { get; private set; }

    public BillingPeriod BillingCycle { get; private set; }

    public DateTimeOffset StartedAtUtc { get; private set; }

    public DateTimeOffset ExpiresAtUtc { get; private set; }

    public bool IsAutoRenew { get; private set; }

    public DateTimeOffset? CancelledAtUtc { get; private set; }

    /// <summary>Razorpay order_id returned from <c>POST /v1/orders</c>.</summary>
    public string? RazorpayOrderId { get; private set; }

    /// <summary>Razorpay payment_id confirmed by the client or webhook.</summary>
    public string? RazorpayPaymentId { get; private set; }

    /// <summary>Checkout signature, kept for audit. Null when activation came from the webhook.</summary>
    public string? RazorpaySignature { get; private set; }

    /// <summary>Plan price in paise, before any discount.</summary>
    public long AmountPaise { get; private set; }

    public string Currency { get; private set; }

    public string? CouponCode { get; private set; }

    public long DiscountPaise { get; private set; }

    /// <summary>What the gateway order is for.</summary>
    public long ChargePaise => AmountPaise - DiscountPaise;

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<Subscription> Create(
        Guid userId, Guid planId, BillingPeriod billingCycle,
        long amountPaise, string? currency, string? couponCode, long discountPaise)
    {
        if (userId == Guid.Empty || planId == Guid.Empty)
        {
            return Error.Validation("Subscription.ReferenceRequired", "User and plan are required.");
        }

        var subscription = new Subscription(Guid.CreateVersion7(), userId, planId, billingCycle);
        var priced = subscription.Reprice(amountPaise, currency, couponCode, discountPaise);
        return priced.IsFailure ? Result.Failure<Subscription>(priced.Error) : subscription;
    }

    /// <summary>Re-prices a still-pending subscription when the user retries checkout (e.g. with another coupon).</summary>
    public Result Reprice(long amountPaise, string? currency, string? couponCode, long discountPaise)
    {
        if (Status != SubscriptionStatus.PendingPayment)
        {
            return BillingErrors.NotPending;
        }

        if (amountPaise < 0 || discountPaise < 0 || discountPaise > amountPaise)
        {
            return Error.Validation("Subscription.InvalidAmount", "Amount and discount must be non-negative, discount not above amount.");
        }

        AmountPaise = amountPaise;
        Currency = string.IsNullOrWhiteSpace(currency) ? DefaultCurrency : currency.Trim().ToUpperInvariant();
        CouponCode = couponCode;
        DiscountPaise = discountPaise;
        return Result.Success();
    }

    public void AttachGatewayOrder(string orderId)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(orderId);
        RazorpayOrderId = orderId;
    }

    /// <summary>
    /// Whether a payment reported by the gateway (webhook or reconciliation) is for exactly what this subscription's
    /// order charges. Guards activation against a payment for a stale price or the wrong currency.
    /// </summary>
    public bool IsChargedBy(long paidPaise, string? paidCurrency) =>
        paidPaise == ChargePaise
        && string.Equals(paidCurrency?.Trim(), Currency, StringComparison.OrdinalIgnoreCase);

    /// <summary>
    /// Confirms payment. Idempotent: activating again with the same payment is a no-op, which lets the client
    /// callback and the webhook race safely. <paramref name="continueFrom"/> is the expiry of a subscription being
    /// renewed early, so the new period starts where the old one ends instead of losing the remaining days.
    /// </summary>
    public Result Activate(string paymentId, string? signature, DateTimeOffset now, DateTimeOffset? continueFrom = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(paymentId);

        if (Status == SubscriptionStatus.Active)
        {
            return RazorpayPaymentId == paymentId ? Result.Success() : BillingErrors.PaymentMismatch;
        }

        if (Status != SubscriptionStatus.PendingPayment)
        {
            return BillingErrors.NotPending;
        }

        var periodStart = continueFrom > now ? continueFrom.Value : now;

        Status = SubscriptionStatus.Active;
        RazorpayPaymentId = paymentId;
        RazorpaySignature = signature;
        StartedAtUtc = now;
        ExpiresAtUtc = BillingCycle == BillingPeriod.Yearly ? periodStart.AddYears(1) : periodStart.AddMonths(1);
        IsAutoRenew = false;
        return Result.Success();
    }

    public Result Cancel(DateTimeOffset cancelledAtUtc)
    {
        if (Status != SubscriptionStatus.Active)
        {
            return Error.BusinessRule("Subscription.NotActive", "Only an active subscription can be cancelled.");
        }

        Status = SubscriptionStatus.Cancelled;
        IsAutoRenew = false;
        CancelledAtUtc = cancelledAtUtc;
        return Result.Success();
    }

    /// <summary>Ends an active period: lapsed without renewal (admin) or superseded by an early renewal.</summary>
    public Result Expire()
    {
        if (Status != SubscriptionStatus.Active)
        {
            return Error.BusinessRule("Subscription.NotActive", "Only an active subscription can be expired.");
        }

        Status = SubscriptionStatus.Expired;
        IsAutoRenew = false;
        return Result.Success();
    }
}
