using FluentValidation;
using MolBhav.Domain.Billing;

namespace MolBhav.Application.Features.Billing.Admin.UpdatePlan;

internal sealed class UpdatePlanCommandValidator : AbstractValidator<UpdatePlanCommand>
{
    public UpdatePlanCommandValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(Plan.NameMaxLength);
        RuleFor(x => x.Price).NotNull().WithMessage("price is required.");
        RuleFor(x => x.Price!.Value).GreaterThanOrEqualTo(0).When(x => x.Price is not null);
        RuleFor(x => x.IsActive).NotNull().WithMessage("isActive is required.");
    }
}
