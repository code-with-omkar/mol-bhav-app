using FluentValidation;
using MolBhav.Domain.Billing;

namespace MolBhav.Application.Features.Billing.ValidateCoupon;

internal sealed class ValidateCouponQueryValidator : AbstractValidator<ValidateCouponQuery>
{
    public ValidateCouponQueryValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(Coupon.CodeMaxLength);
        RuleFor(x => x.PlanCode).NotEmpty().MaximumLength(Plan.CodeMaxLength);
    }
}
