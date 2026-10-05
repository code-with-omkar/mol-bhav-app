using FluentValidation;

namespace MolBhav.Application.Features.Ingestion.Admin.ImportIngestionFile;

internal sealed class ImportIngestionFileCommandValidator : AbstractValidator<ImportIngestionFileCommand>
{
    /// <summary>A full national day from data.gov.in is ~2–3 MB as CSV; 10 MB leaves room for a few days in one file.</summary>
    public const long MaxFileBytes = 10 * 1024 * 1024;

    public ImportIngestionFileCommandValidator()
    {
        RuleFor(x => x.PriceSourceId).NotEmpty();
        RuleFor(x => x.UploadedByUserId).NotEmpty();
        RuleFor(x => x.FileName)
            .NotEmpty()
            .Must(n => n.EndsWith(".csv", StringComparison.OrdinalIgnoreCase))
            .WithMessage("Upload a .csv file.");
        RuleFor(x => x.FileLength)
            .GreaterThan(0).WithMessage("The file is empty.")
            .LessThanOrEqualTo(MaxFileBytes).WithMessage("The file is larger than 10 MB. Split it by date or state.");
    }
}
