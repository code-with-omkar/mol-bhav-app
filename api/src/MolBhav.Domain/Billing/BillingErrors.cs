using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Billing;

public static class BillingErrors
{
    public static readonly Error PlanNotFound =
        Error.NotFound("Plan.NotFound", "The plan does not exist or is not on sale.");

    public static readonly Error SubscriptionNotFound =
        Error.NotFound("Subscription.NotFound", "No subscription found for this order.");

    public static readonly Error AlreadySubscribed =
        Error.Conflict("Subscription.AlreadyActive", "You already have an active subscription that is not due for renewal.");

    public static readonly Error NotPending =
        Error.BusinessRule("Subscription.NotPending", "Only a subscription awaiting payment can be activated.");

    public static readonly Error PaymentMismatch =
        Error.Conflict("Subscription.PaymentMismatch", "This subscription was already activated by a different payment.");

    public static readonly Error PaymentAmountMismatch =
        Error.Conflict("Subscription.PaymentAmountMismatch", "The payment amount or currency does not match what this subscription charges.");

    public static readonly Error InvalidSignature =
        Error.Validation("Payment.InvalidSignature", "Payment signature verification failed.");

    public static readonly Error GatewayUnavailable =
        Error.Unavailable("Payment.GatewayUnavailable", "The payment gateway is unavailable. Try again shortly.");

    public static readonly Error CouponInvalid =
        Error.Validation("Coupon.Invalid", "The coupon is invalid, expired, or not applicable to this plan.");

    public static readonly Error CouponNotFound =
        Error.NotFound("Coupon.NotFound", "Coupon not found.");

    public static readonly Error CouponDuplicate =
        Error.Conflict("Coupon.Duplicate", "A coupon with this code already exists.");

    public static readonly Error CouponMaxUsesBelowUsage =
        Error.Validation("Coupon.MaxUsesBelowUsage", "Max uses cannot be lower than the number of times the coupon was already used.");
}
