using FluentValidation;

namespace MolBhav.Application.Features.Market.GetSuppliers;

internal sealed class GetSuppliersQueryValidator : AbstractValidator<GetSuppliersQuery>
{
    public const int SearchMaxLength = 60;

    public GetSuppliersQueryValidator() => RuleFor(x => x.Search).MaximumLength(SearchMaxLength);
}
