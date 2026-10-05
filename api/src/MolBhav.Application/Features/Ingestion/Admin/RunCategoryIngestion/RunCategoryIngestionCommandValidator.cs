using FluentValidation;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Ingestion.Admin.RunCategoryIngestion;

internal sealed class RunCategoryIngestionCommandValidator : AbstractValidator<RunCategoryIngestionCommand>
{
    public RunCategoryIngestionCommandValidator()
    {
        RuleFor(x => x.CategoryCode).NotEmpty().MaximumLength(ProcurementCategoryCode.MaxLength);
        RuleFor(x => x.RequestedByUserId).NotEmpty();
    }
}
