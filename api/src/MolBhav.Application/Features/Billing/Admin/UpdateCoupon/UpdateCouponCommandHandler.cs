using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Admin.UpdateCoupon;

internal sealed class UpdateCouponCommandHandler(ICouponRepository coupons) : ICommandHandler<UpdateCouponCommand>
{
    public async Task<Result> Handle(UpdateCouponCommand request, CancellationToken cancellationToken)
    {
        var coupon = await coupons.GetByIdAsync(request.Id, cancellationToken);
        return coupon is null
            ? BillingErrors.CouponNotFound
            : coupon.Update(request.IsActive, request.ValidTo, request.MaxUses);
    }
}
