using FluentValidation;

namespace MolBhav.Application.Features.Pricing.GetLatestByLocation;

internal sealed class GetLatestByLocationQueryValidator : AbstractValidator<GetLatestByLocationQuery>
{
    public GetLatestByLocationQueryValidator()
    {
        RuleFor(x => x.LocationKind).IsInEnum();
        RuleFor(x => x.LocationId).NotEmpty();
    }
}
