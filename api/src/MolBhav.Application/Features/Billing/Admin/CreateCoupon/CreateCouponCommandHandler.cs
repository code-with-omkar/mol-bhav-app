using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Admin.CreateCoupon;

internal sealed class CreateCouponCommandHandler(ICouponRepository coupons) : ICommandHandler<CreateCouponCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreateCouponCommand request, CancellationToken cancellationToken)
    {
        if (await coupons.GetByCodeAsync(Coupon.NormaliseCode(request.Code), cancellationToken) is not null)
        {
            return BillingErrors.CouponDuplicate;
        }

        var coupon = Coupon.Create(
            request.Code, request.DiscountType, request.DiscountValue,
            request.MaxUses, request.ValidFrom, request.ValidTo,
            request.ApplicablePlanCode, request.MinAmountPaise);

        if (coupon.IsFailure)
        {
            return Result.Failure<CreatedResponse>(coupon.Error);
        }

        coupons.Add(coupon.Value);
        return new CreatedResponse(coupon.Value.Id);
    }
}
