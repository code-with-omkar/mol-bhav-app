using FluentValidation;
using MolBhav.Domain.Pricing;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Pricing.Admin.UpdatePriceSource;

internal sealed class UpdatePriceSourceCommandValidator : AbstractValidator<UpdatePriceSourceCommand>
{
    public UpdatePriceSourceCommandValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(PricingRules.SourceNameMaxLength);
        RuleFor(x => x.IsActive).NotNull().WithMessage("isActive is required.");
        RuleFor(x => x.CategoryCode).NotEmpty().MaximumLength(ProcurementCategoryCode.MaxLength);
    }
}
