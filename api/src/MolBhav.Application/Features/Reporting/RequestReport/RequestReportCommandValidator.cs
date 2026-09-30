using System.Globalization;
using FluentValidation;
using MolBhav.Domain.Reporting;

namespace MolBhav.Application.Features.Reporting.RequestReport;

internal sealed class RequestReportCommandValidator : AbstractValidator<RequestReportCommand>
{
    public RequestReportCommandValidator()
    {
        RuleFor(x => x.ReportType).NotNull().WithMessage("reportType is required.");
        RuleFor(x => x.ReportType!.Value).IsInEnum().When(x => x.ReportType is not null);

        RuleFor(x => x.Format).NotNull().WithMessage("format is required.");
        RuleFor(x => x.Format!.Value).IsInEnum().When(x => x.Format is not null);

        RuleFor(x => x)
            .Must(x => ReportParameters.IsSupported(x.ReportType!.Value, x.Format!.Value))
            .WithErrorCode("Report.Unsupported")
            .WithMessage("Supported reports: WeeklySummary as Pdf, PriceHistory as Csv.")
            .When(x => x.ReportType is not null && x.Format is not null);

        RuleFor(x => Param(x, ReportParameters.FromDate))
            .Must(BeDateOrEmpty).WithMessage($"parameters.fromDate must be {ReportParameters.DateFormat}.")
            .OverridePropertyName("parameters.fromDate");
        RuleFor(x => Param(x, ReportParameters.ToDate))
            .Must(BeDateOrEmpty).WithMessage($"parameters.toDate must be {ReportParameters.DateFormat}.")
            .OverridePropertyName("parameters.toDate");

        RuleFor(x => x)
            .Must(x => RangeWithinLimit(Param(x, ReportParameters.FromDate), Param(x, ReportParameters.ToDate)))
            .WithErrorCode("Report.InvalidDateRange")
            .WithMessage($"parameters.fromDate must be on or before toDate, at most {ReportParameters.MaxRangeDays} days apart.")
            .When(x => TryDate(Param(x, ReportParameters.FromDate), out _) && TryDate(Param(x, ReportParameters.ToDate), out _));

        RuleFor(x => Param(x, ReportParameters.ProductId))
            .Must(v => Guid.TryParse(v, out _)).WithMessage("parameters.productId is required and must be a uuid.")
            .OverridePropertyName("parameters.productId")
            .When(x => x.ReportType == ReportType.PriceHistory);

        RuleFor(x => Param(x, ReportParameters.MandiId))
            .Must(v => string.IsNullOrEmpty(v) || Guid.TryParse(v, out _)).WithMessage("parameters.mandiId must be a uuid.")
            .OverridePropertyName("parameters.mandiId");
    }

    private static string? Param(RequestReportCommand command, string key) =>
        command.Parameters is not null && command.Parameters.TryGetValue(key, out var value) ? value : null;

    private static bool BeDateOrEmpty(string? value) => string.IsNullOrEmpty(value) || TryDate(value, out _);

    private static bool TryDate(string? value, out DateOnly date) =>
        DateOnly.TryParseExact(value, ReportParameters.DateFormat, CultureInfo.InvariantCulture, DateTimeStyles.None, out date);

    private static bool RangeWithinLimit(string? from, string? to) =>
        TryDate(from, out var start) && TryDate(to, out var end)
        && start <= end && end.DayNumber - start.DayNumber < ReportParameters.MaxRangeDays;
}
