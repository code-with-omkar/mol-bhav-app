using System.Globalization;
using System.Text.Json;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Reporting;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Reporting;

namespace MolBhav.Application.Features.Reporting.RequestReport;

internal sealed class RequestReportCommandHandler(
    IReportRepository reports,
    ICurrentUser currentUser,
    ILanguageContext languageContext,
    TimeProvider timeProvider)
    : ICommandHandler<RequestReportCommand, CreatedResponse>
{
    private const int DefaultRangeDays = 7;
    private static readonly TimeSpan IndiaOffset = TimeSpan.FromHours(5.5);

    public Task<Result<CreatedResponse>> Handle(RequestReportCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        var reportType = request.ReportType!.Value;

        if (ReportParameters.RequiresPro(reportType)
            && !string.Equals(currentUser.SubscriptionTier, SubscriptionTiers.Pro, StringComparison.OrdinalIgnoreCase))
        {
            return Task.FromResult(Result.Failure<CreatedResponse>(
                Error.Forbidden("Report.ProRequired", "This report needs a Pro subscription.")));
        }

        // Generation runs in the background without the request's language or clock, so defaults are fixed here.
        var now = timeProvider.GetUtcNow();
        var parameters = new Dictionary<string, string>(request.Parameters ?? new Dictionary<string, string>(), StringComparer.Ordinal);
        // Users are in India (one zone, no DST): "today" is the IST date.
        var today = DateOnly.FromDateTime(now.ToOffset(IndiaOffset).DateTime);
        parameters.TryAdd(ReportParameters.ToDate, today.ToString(ReportParameters.DateFormat, CultureInfo.InvariantCulture));
        parameters.TryAdd(
            ReportParameters.FromDate,
            today.AddDays(-(DefaultRangeDays - 1)).ToString(ReportParameters.DateFormat, CultureInfo.InvariantCulture));
        parameters.TryAdd(ReportParameters.Language, languageContext.CurrentLanguage);

        var report = Report.Create(userId, reportType, request.Format!.Value, JsonSerializer.Serialize(parameters), now);
        if (report.IsFailure)
        {
            return Task.FromResult(Result.Failure<CreatedResponse>(report.Error));
        }

        reports.Add(report.Value);
        return Task.FromResult(Result.Success(new CreatedResponse(report.Value.Id)));
    }
}
