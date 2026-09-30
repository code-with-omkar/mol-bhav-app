using FluentValidation;
using MolBhav.Domain.Procurement;

namespace MolBhav.Application.Features.Procurement.Admin.CreateCostComponent;

internal sealed class CreateCostComponentCommandValidator : AbstractValidator<CreateCostComponentCommand>
{
    public CreateCostComponentCommandValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(CostComponent.CodeMaxLength);
        RuleFor(x => x.Name).NotEmpty().MaximumLength(CostComponent.NameMaxLength);
        RuleFor(x => x.ComponentType).NotNull().WithMessage("componentType is required.");
        RuleFor(x => x.ComponentType!.Value).IsInEnum().When(x => x.ComponentType is not null);
        RuleFor(x => x.Value).NotNull().WithMessage("value is required.");
    }
}
