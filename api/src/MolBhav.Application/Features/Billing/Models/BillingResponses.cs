using System.Text.Json;
using MolBhav.Domain.Billing;

namespace MolBhav.Application.Features.Billing.Models;

/// <summary>What the mobile client needs to open Razorpay checkout. <see cref="IsStub"/> tells a debug build it can
/// skip the SDK and activate directly.</summary>
public sealed record SubscribeResponseDto(
    Guid SubscriptionId,
    string GatewayOrderId,
    long AmountPaise,
    string Currency,
    string KeyId,
    string PlanName,
    BillingPeriod BillingCycle,
    bool IsStub);

/// <summary>Invalid coupons are a 200 with <see cref="IsValid"/> false, so the checkout screen can show the reason inline.</summary>
public sealed record CouponValidationDto(
    bool IsValid,
    DiscountType? DiscountType,
    long? DiscountValue,
    long OriginalAmountPaise,
    long DiscountPaise,
    long FinalAmountPaise,
    string Message);

public sealed record PlanResponse(Guid Id, string Code, string Name, decimal Price, string Currency, BillingPeriod BillingPeriod);

public sealed record AdminPlanResponse(Guid Id, string Code, string Name, decimal Price, string Currency, BillingPeriod BillingPeriod, bool IsActive);

public sealed record SubscriptionResponse(
    Guid Id,
    Guid PlanId,
    string PlanCode,
    string PlanName,
    SubscriptionStatus Status,
    BillingPeriod BillingCycle,
    DateTimeOffset StartedAtUtc,
    DateTimeOffset ExpiresAtUtc,
    bool IsAutoRenew,
    DateTimeOffset? CancelledAtUtc);

public sealed record AdminSubscriptionResponse(
    Guid Id,
    Guid UserId,
    Guid PlanId,
    string PlanCode,
    SubscriptionStatus Status,
    DateTimeOffset StartedAtUtc,
    DateTimeOffset ExpiresAtUtc,
    bool IsAutoRenew,
    DateTimeOffset? CancelledAtUtc);

public sealed record AdminCouponResponse(
    Guid Id,
    string Code,
    DiscountType DiscountType,
    long DiscountValue,
    int? MaxUses,
    int UsesCount,
    DateTimeOffset ValidFrom,
    DateTimeOffset? ValidTo,
    string? ApplicablePlanCode,
    long MinAmountPaise,
    bool IsActive);

/// <summary>Where a gateway webhook is in the inbox.</summary>
public enum WebhookInboxState
{
    /// <summary>Not applied yet: due now or waiting out a retry backoff.</summary>
    Pending = 0,

    Processed = 1,

    /// <summary>Retrying can't help; needs a human, then a replay.</summary>
    Parked = 2,
}

/// <summary>One inbox row for the admin list (no payload).</summary>
public sealed record AdminWebhookResponse(
    Guid Id,
    string Provider,
    string EventId,
    string EventType,
    WebhookInboxState State,
    int AttemptCount,
    DateTimeOffset ReceivedAtUtc,
    DateTimeOffset NextAttemptAtUtc,
    DateTimeOffset? LastAttemptAtUtc,
    DateTimeOffset? ProcessedAtUtc,
    DateTimeOffset? ParkedAtUtc,
    string? LastError);

/// <summary>An inbox row with the raw gateway payload, as received (rendered as JSON, not a string).</summary>
public sealed record AdminWebhookDetailResponse(AdminWebhookResponse Webhook, JsonElement Payload);
