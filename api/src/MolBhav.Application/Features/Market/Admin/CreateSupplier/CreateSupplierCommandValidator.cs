using FluentValidation;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.CreateSupplier;

internal sealed class CreateSupplierCommandValidator : AbstractValidator<CreateSupplierCommand>
{
    public CreateSupplierCommandValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(MarketCode.MaxLength);
        RuleFor(x => x.DistrictId).NotEmpty();
        RuleFor(x => x.Name).NotEmpty().MaximumLength(MarketRules.NameMaxLength);
        RuleFor(x => x.ContactPhone).MaximumLength(MarketRules.ContactPhoneMaxLength);
    }
}
