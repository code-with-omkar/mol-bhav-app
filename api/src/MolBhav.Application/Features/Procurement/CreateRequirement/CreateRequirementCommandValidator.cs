using FluentValidation;

namespace MolBhav.Application.Features.Procurement.CreateRequirement;

internal sealed class CreateRequirementCommandValidator : AbstractValidator<CreateRequirementCommand>
{
    public CreateRequirementCommandValidator()
    {
        RuleFor(x => x.ProductId).NotEmpty();
        RuleFor(x => x.UnitId).NotEmpty();
        RuleFor(x => x.Quantity).GreaterThan(0);
        RuleFor(x => x.TargetPrice).GreaterThan(0).When(x => x.TargetPrice is not null);
    }
}
