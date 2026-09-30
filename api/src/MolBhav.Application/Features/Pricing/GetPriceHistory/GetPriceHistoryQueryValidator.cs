using FluentValidation;

namespace MolBhav.Application.Features.Pricing.GetPriceHistory;

internal sealed class GetPriceHistoryQueryValidator : AbstractValidator<GetPriceHistoryQuery>
{
    public GetPriceHistoryQueryValidator()
    {
        RuleFor(x => x.ProductId).NotEmpty();
        RuleFor(x => x.LocationId).NotEmpty();
        RuleFor(x => x.ToDate).GreaterThanOrEqualTo(x => x.FromDate).WithMessage("toDate must not be before fromDate.");
    }
}
