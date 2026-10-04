using System.Globalization;
using FluentValidation;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Ingestion.Admin.UpdateIngestionSchedule;

internal sealed class UpdateIngestionScheduleCommandValidator : AbstractValidator<UpdateIngestionScheduleCommand>
{
    public const string TimeFormat = "HH:mm";

    public UpdateIngestionScheduleCommandValidator()
    {
        RuleFor(x => x.PriceSourceId).NotEmpty();
        RuleFor(x => x.IsEnabled).NotNull().WithMessage("isEnabled is required.");
        RuleFor(x => x.Frequency).NotNull().IsInEnum();
        RuleFor(x => x.TimeOfDay)
            .NotEmpty()
            .Must(t => TryParseTime(t, out _))
            .WithMessage("timeOfDay must be HH:mm (24-hour, IST).");
        RuleFor(x => x.DayOfWeek)
            .NotNull().IsInEnum()
            .When(x => x.Frequency == IngestionScheduleFrequency.Weekly)
            .WithMessage("dayOfWeek is required for a weekly schedule.");
        RuleFor(x => x.IntervalHours)
            .NotNull()
            .Must(h => h is not null && IngestionSchedule.AllowedIntervalHours.Contains(h.Value))
            .When(x => x.Frequency == IngestionScheduleFrequency.EveryNHours)
            .WithMessage($"intervalHours must be one of {string.Join(", ", IngestionSchedule.AllowedIntervalHours.Order())}.");
    }

    internal static bool TryParseTime(string? value, out TimeOnly time) =>
        TimeOnly.TryParseExact(value, TimeFormat, CultureInfo.InvariantCulture, DateTimeStyles.None, out time);
}
