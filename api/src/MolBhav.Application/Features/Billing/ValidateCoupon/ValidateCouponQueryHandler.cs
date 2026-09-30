using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.ValidateCoupon;

internal sealed class ValidateCouponQueryHandler(
    IPlanRepository plans,
    ICouponRepository coupons,
    TimeProvider timeProvider) : IQueryHandler<ValidateCouponQuery, CouponValidationDto>
{
    public async Task<Result<CouponValidationDto>> Handle(ValidateCouponQuery request, CancellationToken cancellationToken)
    {
        var plan = await plans.GetByCodeAsync(request.PlanCode, cancellationToken);
        if (plan is null || !plan.IsActive)
        {
            return BillingErrors.PlanNotFound;
        }

        var amount = plan.PricePaise;
        var coupon = await coupons.GetByCodeAsync(Coupon.NormaliseCode(request.Code), cancellationToken);

        if (coupon is null || !coupon.IsRedeemableFor(plan.Code, amount, timeProvider.GetUtcNow()))
        {
            return new CouponValidationDto(false, null, null, amount, 0, amount, BillingErrors.CouponInvalid.Description);
        }

        var discount = coupon.CalculateDiscount(amount);
        return new CouponValidationDto(
            true, coupon.DiscountType, coupon.DiscountValue, amount, discount, amount - discount, "Coupon applied.");
    }
}
