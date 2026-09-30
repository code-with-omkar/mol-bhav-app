using FluentValidation;

namespace MolBhav.Application.Features.Market.GetMandis;

internal sealed class GetMandisQueryValidator : AbstractValidator<GetMandisQuery>
{
    public const int SearchMaxLength = 60;

    public GetMandisQueryValidator() => RuleFor(x => x.Search).MaximumLength(SearchMaxLength);
}
