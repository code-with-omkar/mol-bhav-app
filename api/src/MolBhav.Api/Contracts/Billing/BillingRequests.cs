using MolBhav.Domain.Billing;

namespace MolBhav.Api.Contracts.Billing;

/// <summary>The plan code identifies the billing cycle (one plan per cycle); the amount always comes from the server.</summary>
public sealed record SubscribeRequest(string? PlanCode, string? CouponCode);

public sealed record ValidateCouponRequest(string? Code, string? PlanCode);

public sealed record ActivateSubscriptionRequest(
    string? RazorpayOrderId,
    string? RazorpayPaymentId,
    string? RazorpaySignature);

public sealed record CreatePlanRequest(string? Code, string? Name, decimal? Price, string? Currency, BillingPeriod? BillingPeriod);

/// <summary>Both fields are required — there is no partial update, so a missing one can't silently deactivate a plan.</summary>
public sealed record UpdatePlanRequest(string? Name, decimal? Price, bool? IsActive);

public sealed record CreateCouponRequest(
    string? Code,
    DiscountType? DiscountType,
    long? DiscountValue,
    int? MaxUses,
    DateTimeOffset? ValidFrom,
    DateTimeOffset? ValidTo,
    string? ApplicablePlanCode,
    long MinAmountPaise);

/// <summary>Replaces all editable fields: null <c>ValidTo</c> / <c>MaxUses</c> mean open-ended / unlimited.</summary>
public sealed record UpdateCouponRequest(bool IsActive, DateTimeOffset? ValidTo, int? MaxUses);
