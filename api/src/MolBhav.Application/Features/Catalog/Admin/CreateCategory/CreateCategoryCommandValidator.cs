using FluentValidation;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Catalog.Admin.CreateCategory;

internal sealed class CreateCategoryCommandValidator : AbstractValidator<CreateCategoryCommand>
{
    public CreateCategoryCommandValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(ProcurementCategoryCode.MaxLength);
        RuleFor(x => x.IconKey).MaximumLength(ProcurementCategory.IconKeyMaxLength);
        RuleFor(x => x.DisplayOrder).DisplayOrderRules();
        RuleFor(x => x.Translations).TranslationsRules();
    }
}
