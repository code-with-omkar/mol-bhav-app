using System.Globalization;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Application.Abstractions.Reporting;
using MolBhav.Application.Common.Models;
using MolBhav.Domain.Reporting;
using MolBhav.Infrastructure.Persistence;

namespace MolBhav.Infrastructure.Reporting;

/// <summary>
/// Renders <see cref="ReportType.WeeklySummary"/> as PDF (QuestPDF) and <see cref="ReportType.PriceHistory"/> as CSV,
/// and stages the file in <c>reporting.report_files</c>; the calling handler's unit of work saves file and status together.
/// </summary>
internal sealed partial class ReportGenerator(
    MolBhavDbContext dbContext,
    ReportDataReader data,
    IAlertingReadService alerts,
    IProcurementReadService procurement,
    TimeProvider timeProvider,
    ILogger<ReportGenerator> logger) : IReportGenerator
{
    private const int MaxRequirements = 20;
    private const string PdfType = "application/pdf";
    private const string CsvType = "text/csv; charset=utf-8";

    public async Task<ReportGenerationOutcome> GenerateAsync(ReportGenerationRequest request, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        if (!ReportParameters.IsSupported(request.ReportType, request.Format))
        {
            return ReportGenerationOutcome.Failed($"{request.ReportType} reports are not available as {request.Format}.");
        }

        var parameters = JsonSerializer.Deserialize<Dictionary<string, string>>(request.ParametersJson) ?? [];
        if (!TryDate(parameters, ReportParameters.FromDate, out var fromDate) || !TryDate(parameters, ReportParameters.ToDate, out var toDate))
        {
            return ReportGenerationOutcome.Failed("The report's date range is missing or invalid.");
        }

        var language = parameters.GetValueOrDefault(ReportParameters.Language) ?? "en";
        var range = $"{fromDate:yyyy-MM-dd}-to-{toDate:yyyy-MM-dd}";

        (string FileName, string ContentType, byte[] Content) file;
        try
        {
            file = request.ReportType switch
            {
                ReportType.WeeklySummary => (
                    $"molbhav-weekly-summary-{range}.pdf",
                    PdfType,
                    WeeklySummaryDocument.Render(
                        await LoadWeeklySummaryAsync(request.UserId, fromDate, toDate, language, cancellationToken), language)),
                _ => await PriceHistoryAsync(parameters, fromDate, toDate, language, range, cancellationToken),
            };
        }
        catch (Exception ex) when (ex is not OperationCanceledException and not DbUpdateException and not System.Data.Common.DbException)
        {
            LogRenderFailed(logger, ex, request.ReportId, request.ReportType);
            return ReportGenerationOutcome.Failed("The report could not be rendered.");
        }

        var now = timeProvider.GetUtcNow();
        var existing = await dbContext.Set<ReportFile>().FindAsync([request.ReportId], cancellationToken);
        if (existing is null)
        {
            dbContext.Set<ReportFile>().Add(new ReportFile(request.ReportId, file.FileName, file.ContentType, file.Content, now));
        }
        else
        {
            existing.Replace(file.FileName, file.ContentType, file.Content, now);
        }

        return ReportGenerationOutcome.Success($"/api/v1/reports/{request.ReportId}/download");
    }

    private async Task<(string, string, byte[])> PriceHistoryAsync(
        Dictionary<string, string> parameters, DateOnly fromDate, DateOnly toDate, string language, string range, CancellationToken cancellationToken)
    {
        var productId = Guid.Parse(parameters[ReportParameters.ProductId], CultureInfo.InvariantCulture);
        Guid? mandiId = parameters.TryGetValue(ReportParameters.MandiId, out var mandi) && Guid.TryParse(mandi, out var id) ? id : null;

        var rows = await data.GetPriceHistoryAsync(productId, mandiId, fromDate, toDate, language, cancellationToken);
        return ($"molbhav-price-history-{range}.csv", CsvType, PriceHistoryCsv.Write(rows));
    }

    private async Task<WeeklySummaryData> LoadWeeklySummaryAsync(
        Guid userId, DateOnly fromDate, DateOnly toDate, string language, CancellationToken cancellationToken)
    {
        var preference = new LanguagePreference(language, "en");

        var watchlist = await data.GetWatchlistPeriodAsync(userId, fromDate, toDate, language, cancellationToken);
        var displayName = await data.GetDisplayNameAsync(userId, cancellationToken);

        // Newest first; one page covers a normal week, older pages would fall outside the range anyway.
        var recentAlerts = await alerts.GetAlertsAsync(userId, preference, new PageRequest(1, PageRequest.MaxPageSize), cancellationToken);
        var alertsInRange = recentAlerts.Items
            .Where(a =>
            {
                var day = DateOnly.FromDateTime(a.TriggeredAtUtc.ToOffset(WeeklySummaryDocument.IndiaOffset).DateTime);
                return day >= fromDate && day <= toDate;
            })
            .ToList();

        var opportunities = new List<OpportunitySummary>();
        foreach (var requirement in (await procurement.GetMyRequirementsAsync(userId, preference, cancellationToken)).Take(MaxRequirements))
        {
            var options = await procurement.GetOpportunitiesAsync(requirement.Id, userId, cancellationToken);
            var best = options.Count > 0 ? options[0] : null;
            opportunities.Add(new OpportunitySummary(
                string.IsNullOrWhiteSpace(requirement.VariantName) ? requirement.Product.Name : $"{requirement.Product.Name} · {requirement.VariantName}",
                requirement.Quantity,
                requirement.Unit.Symbol,
                best?.LocationName,
                best?.EstimatedCost,
                best?.SavingsVsTarget));
        }

        return new WeeklySummaryData(displayName, fromDate, toDate, timeProvider.GetUtcNow(), watchlist, alertsInRange, opportunities);
    }

    private static bool TryDate(Dictionary<string, string> parameters, string key, out DateOnly date)
    {
        date = default;
        return parameters.TryGetValue(key, out var value)
            && DateOnly.TryParseExact(value, ReportParameters.DateFormat, CultureInfo.InvariantCulture, DateTimeStyles.None, out date);
    }

    [LoggerMessage(Level = LogLevel.Error, Message = "Rendering {ReportType} report {ReportId} failed")]
    private static partial void LogRenderFailed(ILogger logger, Exception exception, Guid reportId, ReportType reportType);
}
