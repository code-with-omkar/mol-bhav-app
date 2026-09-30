using FluentValidation;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.UpdateSupplier;

internal sealed class UpdateSupplierCommandValidator : AbstractValidator<UpdateSupplierCommand>
{
    public UpdateSupplierCommandValidator()
    {
        RuleFor(x => x.DistrictId).NotEmpty();
        RuleFor(x => x.Name).NotEmpty().MaximumLength(MarketRules.NameMaxLength);
        RuleFor(x => x.ContactPhone).MaximumLength(MarketRules.ContactPhoneMaxLength);
        RuleFor(x => x.IsActive).NotNull().WithMessage("isActive is required.");
    }
}
