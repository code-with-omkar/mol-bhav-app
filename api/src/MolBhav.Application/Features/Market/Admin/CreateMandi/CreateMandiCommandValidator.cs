using FluentValidation;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.CreateMandi;

internal sealed class CreateMandiCommandValidator : AbstractValidator<CreateMandiCommand>
{
    public CreateMandiCommandValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(MarketCode.MaxLength);
        RuleFor(x => x.DistrictId).NotEmpty();
        RuleFor(x => x.Name).NotEmpty().MaximumLength(MarketRules.NameMaxLength);
    }
}
