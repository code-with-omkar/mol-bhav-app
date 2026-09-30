using FluentValidation;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.UpdateMandi;

internal sealed class UpdateMandiCommandValidator : AbstractValidator<UpdateMandiCommand>
{
    public UpdateMandiCommandValidator()
    {
        RuleFor(x => x.DistrictId).NotEmpty();
        RuleFor(x => x.Name).NotEmpty().MaximumLength(MarketRules.NameMaxLength);
        RuleFor(x => x.IsActive).NotNull().WithMessage("isActive is required.");
    }
}
