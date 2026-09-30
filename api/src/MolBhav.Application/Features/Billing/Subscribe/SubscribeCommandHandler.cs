using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Subscribe;

/// <summary>
/// Checkout step 1: price the plan server-side (the client never sends an amount), apply a coupon without consuming
/// it, open a gateway order and hand the client what it needs to launch checkout. Step 2 is activation, by the
/// client (<c>ActivateSubscriptionCommand</c>) or the webhook.
/// </summary>
internal sealed class SubscribeCommandHandler(
    IPlanRepository plans,
    ISubscriptionRepository subscriptions,
    ICouponRepository coupons,
    IPaymentGateway paymentGateway,
    ICurrentUser currentUser,
    TimeProvider timeProvider) : ICommandHandler<SubscribeCommand, SubscribeResponseDto>
{
    /// <summary>How close to expiry an active subscriber may pay for the next period.</summary>
    public static readonly TimeSpan RenewalWindow = TimeSpan.FromDays(7);

    public async Task<Result<SubscribeResponseDto>> Handle(SubscribeCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        var now = timeProvider.GetUtcNow();

        var plan = await plans.GetByCodeAsync(request.PlanCode, cancellationToken);
        if (plan is null || !plan.IsActive)
        {
            return BillingErrors.PlanNotFound;
        }

        var active = await subscriptions.GetActiveByUserAsync(userId, cancellationToken);
        if (active is not null && active.ExpiresAtUtc > now + RenewalWindow)
        {
            return BillingErrors.AlreadySubscribed;
        }

        var amount = plan.PricePaise;
        long discount = 0;
        string? couponCode = null;

        if (!string.IsNullOrWhiteSpace(request.CouponCode))
        {
            var coupon = await coupons.GetByCodeAsync(Coupon.NormaliseCode(request.CouponCode), cancellationToken);
            if (coupon is null || !coupon.IsRedeemableFor(plan.Code, amount, now))
            {
                return BillingErrors.CouponInvalid;
            }

            discount = coupon.CalculateDiscount(amount);
            couponCode = coupon.Code;
        }

        var subscription = await subscriptions.GetPendingByUserAndPlanAsync(userId, plan.Id, cancellationToken);
        if (subscription is null)
        {
            var created = Subscription.Create(userId, plan.Id, plan.BillingPeriod, amount, plan.Currency, couponCode, discount);
            if (created.IsFailure)
            {
                return Result.Failure<SubscribeResponseDto>(created.Error);
            }

            subscription = created.Value;
            subscriptions.Add(subscription);
        }
        else
        {
            var repriced = subscription.Reprice(amount, plan.Currency, couponCode, discount);
            if (repriced.IsFailure)
            {
                return Result.Failure<SubscribeResponseDto>(repriced.Error);
            }
        }

        var order = await paymentGateway.CreateOrderAsync(
            new CreateOrderRequest(subscription.Id, plan.Code, subscription.ChargePaise, subscription.Currency, couponCode),
            cancellationToken);

        if (!order.IsSuccess)
        {
            return BillingErrors.GatewayUnavailable;
        }

        subscription.AttachGatewayOrder(order.GatewayOrderId);

        return new SubscribeResponseDto(
            subscription.Id,
            order.GatewayOrderId,
            order.AmountPaise,
            order.Currency,
            paymentGateway.PublicKeyId,
            plan.Name,
            plan.BillingPeriod,
            paymentGateway.IsStub);
    }
}
