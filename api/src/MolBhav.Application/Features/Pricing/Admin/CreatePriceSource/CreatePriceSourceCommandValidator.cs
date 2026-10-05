using FluentValidation;
using MolBhav.Domain.Pricing;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Pricing.Admin.CreatePriceSource;

internal sealed class CreatePriceSourceCommandValidator : AbstractValidator<CreatePriceSourceCommand>
{
    public CreatePriceSourceCommandValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(PricingRules.SourceCodeMaxLength);
        RuleFor(x => x.Name).NotEmpty().MaximumLength(PricingRules.SourceNameMaxLength);
        RuleFor(x => x.CategoryCode).NotEmpty().MaximumLength(ProcurementCategoryCode.MaxLength);
    }
}
