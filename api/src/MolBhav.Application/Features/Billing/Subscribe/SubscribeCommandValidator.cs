using FluentValidation;
using MolBhav.Domain.Billing;

namespace MolBhav.Application.Features.Billing.Subscribe;

internal sealed class SubscribeCommandValidator : AbstractValidator<SubscribeCommand>
{
    public SubscribeCommandValidator()
    {
        RuleFor(x => x.PlanCode).NotEmpty().MaximumLength(Plan.CodeMaxLength);
        RuleFor(x => x.CouponCode).MaximumLength(Coupon.CodeMaxLength);
    }
}
