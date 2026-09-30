using FluentValidation;
using MolBhav.Domain.Billing;

namespace MolBhav.Application.Features.Billing.Admin.CreatePlan;

internal sealed class CreatePlanCommandValidator : AbstractValidator<CreatePlanCommand>
{
    public CreatePlanCommandValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(Plan.CodeMaxLength);
        RuleFor(x => x.Name).NotEmpty().MaximumLength(Plan.NameMaxLength);
        RuleFor(x => x.Price).NotNull().WithMessage("price is required.");
        RuleFor(x => x.Price!.Value).GreaterThanOrEqualTo(0).When(x => x.Price is not null);
        RuleFor(x => x.BillingPeriod).NotNull().WithMessage("billingPeriod is required.");
        RuleFor(x => x.BillingPeriod!.Value).IsInEnum().When(x => x.BillingPeriod is not null);
    }
}
