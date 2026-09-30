using FluentValidation;

namespace MolBhav.Application.Features.Market.Admin.GetAdminMandis;

internal sealed class GetAdminMandisQueryValidator : AbstractValidator<GetAdminMandisQuery>
{
    public const int SearchMaxLength = 60;

    public GetAdminMandisQueryValidator() => RuleFor(x => x.Search).MaximumLength(SearchMaxLength);
}
