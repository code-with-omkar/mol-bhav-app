using FluentValidation;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.AddDistrict;

internal sealed class AddDistrictCommandValidator : AbstractValidator<AddDistrictCommand>
{
    public AddDistrictCommandValidator() => RuleFor(x => x.Name).NotEmpty().MaximumLength(MarketRules.DistrictNameMaxLength);
}
