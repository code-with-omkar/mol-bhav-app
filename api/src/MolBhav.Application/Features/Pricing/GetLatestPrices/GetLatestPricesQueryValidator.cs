using FluentValidation;

namespace MolBhav.Application.Features.Pricing.GetLatestPrices;

internal sealed class GetLatestPricesQueryValidator : AbstractValidator<GetLatestPricesQuery>
{
    public GetLatestPricesQueryValidator() => RuleFor(x => x.ProductId).NotEmpty();
}
