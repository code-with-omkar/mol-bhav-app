using FluentValidation;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.UpdateState;

internal sealed class UpdateStateCommandValidator : AbstractValidator<UpdateStateCommand>
{
    public UpdateStateCommandValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(MarketRules.StateNameMaxLength);
        RuleFor(x => x.IsActive).NotNull().WithMessage("isActive is required.");
    }
}
