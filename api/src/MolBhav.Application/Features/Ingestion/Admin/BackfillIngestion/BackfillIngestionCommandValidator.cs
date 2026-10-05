using FluentValidation;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Ingestion.Admin.BackfillIngestion;

internal sealed class BackfillIngestionCommandValidator : AbstractValidator<BackfillIngestionCommand>
{
    public BackfillIngestionCommandValidator()
    {
        RuleFor(x => x.PriceSourceId).NotEmpty();
        RuleFor(x => x.RequestedByUserId).NotEmpty();
        RuleFor(x => x.FromDate).NotNull().WithMessage("fromDate is required.");
        RuleFor(x => x.ToDate).NotNull().WithMessage("toDate is required.");
        RuleFor(x => x)
            .Must(x => x.FromDate <= x.ToDate)
            .When(x => x.FromDate is not null && x.ToDate is not null)
            .WithName("toDate")
            .WithMessage("toDate must be on or after fromDate.");
        RuleFor(x => x)
            .Must(x => x.ToDate!.Value.DayNumber - x.FromDate!.Value.DayNumber + 1 <= IngestionDates.MaxBackfillDays)
            .When(x => x.FromDate is not null && x.ToDate is not null && x.FromDate <= x.ToDate)
            .WithName("toDate")
            .WithMessage($"A backfill can cover at most {IngestionDates.MaxBackfillDays} days.");
    }
}
