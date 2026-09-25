using FluentValidation;
using MolBhav.Application.Features.Catalog.GetProducts;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Catalog.Admin.GetAdminProducts;

internal sealed class GetAdminProductsQueryValidator : AbstractValidator<GetAdminProductsQuery>
{
    public GetAdminProductsQueryValidator()
    {
        RuleFor(x => x.CategoryCode).MaximumLength(ProcurementCategoryCode.MaxLength);
        RuleFor(x => x.Search).MaximumLength(GetProductsQueryValidator.SearchMaxLength);
    }
}
