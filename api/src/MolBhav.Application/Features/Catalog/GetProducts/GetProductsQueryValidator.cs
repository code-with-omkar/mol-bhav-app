using FluentValidation;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Catalog.GetProducts;

internal sealed class GetProductsQueryValidator : AbstractValidator<GetProductsQuery>
{
    public const int SearchMaxLength = 60;

    public GetProductsQueryValidator()
    {
        RuleFor(x => x.CategoryCode).NotEmpty().MaximumLength(ProcurementCategoryCode.MaxLength);
        RuleFor(x => x.Search).MaximumLength(SearchMaxLength);
    }
}
