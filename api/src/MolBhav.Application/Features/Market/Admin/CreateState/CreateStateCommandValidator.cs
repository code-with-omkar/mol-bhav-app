using FluentValidation;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.CreateState;

internal sealed class CreateStateCommandValidator : AbstractValidator<CreateStateCommand>
{
    public CreateStateCommandValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(MarketRules.StateNameMaxLength);
        RuleFor(x => x.Code).NotEmpty().MaximumLength(MarketRules.StateCodeMaxLength);
    }
}
