using FluentValidation;
using MolBhav.Domain.Procurement;

namespace MolBhav.Application.Features.Procurement.Admin.UpdateCostComponent;

internal sealed class UpdateCostComponentCommandValidator : AbstractValidator<UpdateCostComponentCommand>
{
    public UpdateCostComponentCommandValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(CostComponent.NameMaxLength);
        RuleFor(x => x.Value).NotNull().WithMessage("value is required.");
        RuleFor(x => x.IsActive).NotNull().WithMessage("isActive is required.");
    }
}
