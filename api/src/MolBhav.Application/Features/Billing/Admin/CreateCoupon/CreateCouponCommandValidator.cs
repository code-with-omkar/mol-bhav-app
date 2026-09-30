using FluentValidation;
using MolBhav.Domain.Billing;

namespace MolBhav.Application.Features.Billing.Admin.CreateCoupon;

internal sealed class CreateCouponCommandValidator : AbstractValidator<CreateCouponCommand>
{
    public CreateCouponCommandValidator()
    {
        RuleFor(x => x.Code)
            .NotEmpty()
            .Must(code => code is not null && System.Text.RegularExpressions.Regex.IsMatch(Coupon.NormaliseCode(code), "^[A-Z0-9]{3,50}$"))
            .WithMessage("Code must be 3–50 letters or digits.");
        RuleFor(x => x.DiscountType).IsInEnum();
        RuleFor(x => x.DiscountValue).GreaterThan(0);
        RuleFor(x => x.DiscountValue).LessThanOrEqualTo(100).When(x => x.DiscountType == DiscountType.Percent);
        RuleFor(x => x.MaxUses).GreaterThan(0).When(x => x.MaxUses.HasValue);
        RuleFor(x => x.ValidTo).GreaterThan(x => x.ValidFrom).When(x => x.ValidTo.HasValue);
        RuleFor(x => x.ApplicablePlanCode).MaximumLength(Plan.CodeMaxLength);
        RuleFor(x => x.MinAmountPaise).GreaterThanOrEqualTo(0);
    }
}
