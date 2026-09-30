using FluentValidation;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.UpdateDistrict;

internal sealed class UpdateDistrictCommandValidator : AbstractValidator<UpdateDistrictCommand>
{
    public UpdateDistrictCommandValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(MarketRules.DistrictNameMaxLength);
        RuleFor(x => x.IsActive).NotNull().WithMessage("isActive is required.");
    }
}
