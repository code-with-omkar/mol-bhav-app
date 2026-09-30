using FluentValidation;

namespace MolBhav.Application.Features.Ingestion.Admin.RunIngestionJob;

internal sealed class RunIngestionJobCommandValidator : AbstractValidator<RunIngestionJobCommand>
{
    public RunIngestionJobCommandValidator()
    {
        RuleFor(x => x.PriceSourceId).NotEmpty();
        RuleFor(x => x.TriggerType).IsInEnum();
    }
}
