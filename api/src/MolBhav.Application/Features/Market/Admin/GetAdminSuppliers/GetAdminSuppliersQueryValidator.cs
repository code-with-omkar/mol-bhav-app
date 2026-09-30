using FluentValidation;

namespace MolBhav.Application.Features.Market.Admin.GetAdminSuppliers;

internal sealed class GetAdminSuppliersQueryValidator : AbstractValidator<GetAdminSuppliersQuery>
{
    public const int SearchMaxLength = 60;

    public GetAdminSuppliersQueryValidator() => RuleFor(x => x.Search).MaximumLength(SearchMaxLength);
}
