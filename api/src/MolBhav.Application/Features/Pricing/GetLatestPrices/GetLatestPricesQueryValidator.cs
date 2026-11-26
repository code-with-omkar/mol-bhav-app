using FluentValidation;

namespace MolBhav.Application.Features.Pricing.GetLatestPrices;

internal sealed class GetLatestPricesQueryValidator : AbstractValidator<GetLatestPricesQuery>
{
    public GetLatestPricesQueryValidator()
    {
        RuleFor(x => x.ProductId).NotEmpty();
        RuleFor(x => x.MaxAgeDays).InclusiveBetween(1, 3660);
    }
}
