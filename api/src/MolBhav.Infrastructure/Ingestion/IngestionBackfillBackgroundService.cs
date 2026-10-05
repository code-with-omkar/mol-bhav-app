using MediatR;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Features.Ingestion.Admin.RunIngestionJob;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Runs queued backfills (and category "run all" requests) one source-day at a time — each is a normal Manual <see cref="RunIngestionJobCommand"/> in its
/// own scope and transaction, so a month of data never sits in one transaction and every day appears as its own job.
/// Re-running a day already pulled is harmless: unchanged rows are skipped, corrected rows replace the old ones.
/// </summary>
internal sealed partial class IngestionBackfillBackgroundService(
    IngestionBackfillQueue queue,
    IServiceScopeFactory scopeFactory,
    IOptions<IngestionSchedulerOptions> options,
    ILogger<IngestionBackfillBackgroundService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            await foreach (var request in queue.Reader.ReadAllAsync(stoppingToken))
            {
                foreach (var priceSourceId in request.PriceSourceIds)
                {
                    LogBackfillStarted(logger, priceSourceId, request.Dates.Count);

                    foreach (var date in request.Dates)
                    {
                        await RunOneDayAsync(priceSourceId, request.RequestedByUserId, date, stoppingToken);

                        // Be polite to the public API between days (the adapter also throttles between pages).
                        await Task.Delay(TimeSpan.FromSeconds(options.Value.BackfillDelaySeconds), stoppingToken);
                    }

                    LogBackfillCompleted(logger, priceSourceId, request.Dates.Count);
                }
            }
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Graceful shutdown; unfinished dates are dropped (see IIngestionBackfillQueue).
        }
    }

    private async Task RunOneDayAsync(Guid priceSourceId, Guid requestedByUserId, DateOnly date, CancellationToken cancellationToken)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var sender = scope.ServiceProvider.GetRequiredService<ISender>();

        try
        {
            var result = await sender.Send(
                new RunIngestionJobCommand(priceSourceId, IngestionTriggerType.Manual, requestedByUserId, date),
                cancellationToken);
            if (result.IsFailure)
            {
                LogDayRejected(logger, priceSourceId, date, result.Error.Code, result.Error.Description);
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            LogDayFailed(logger, priceSourceId, date, ex);
        }
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Backfill started for source {PriceSourceId}: {Days} day(s)")]
    private static partial void LogBackfillStarted(ILogger logger, Guid priceSourceId, int days);

    [LoggerMessage(Level = LogLevel.Information, Message = "Backfill finished for source {PriceSourceId}: {Days} day(s)")]
    private static partial void LogBackfillCompleted(ILogger logger, Guid priceSourceId, int days);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Backfill day {Date} for source {PriceSourceId} was rejected: {Code} {Description}")]
    private static partial void LogDayRejected(ILogger logger, Guid priceSourceId, DateOnly date, string code, string description);

    [LoggerMessage(Level = LogLevel.Error, Message = "Backfill day {Date} for source {PriceSourceId} failed")]
    private static partial void LogDayFailed(ILogger logger, Guid priceSourceId, DateOnly date, Exception exception);
}
