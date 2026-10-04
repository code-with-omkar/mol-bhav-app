using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Features.Ingestion.Admin.RunIngestionJob;
using MolBhav.Application.Features.Ingestion.Scheduling.ClaimDueIngestionSchedule;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Runs admin-configured <see cref="IngestionSchedule"/>s (BRD §9/§18). Every <see cref="IngestionSchedulerOptions.PollIntervalSeconds"/>
/// it reads the due schedules, claims each slot in its own transaction (which advances the schedule, so a crash mid-run
/// never re-runs the same slot and two API instances never both run it), then runs the source in a fresh scope.
/// Sources without a schedule are never pulled automatically — an admin must schedule them (or use "Run now").
/// </summary>
internal sealed partial class IngestionSchedulerBackgroundService(
    IServiceScopeFactory scopeFactory,
    IOptions<IngestionSchedulerOptions> options,
    TimeProvider timeProvider,
    ILogger<IngestionSchedulerBackgroundService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var settings = options.Value;

        if (!settings.Enabled)
        {
            LogDisabled(logger);
            return;
        }

        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(settings.PollIntervalSeconds), timeProvider);

        try
        {
            do
            {
                try
                {
                    await RunDueSchedulesAsync(settings.MaxRunsPerTick, stoppingToken);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    LogTickFailed(logger, ex);
                }
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Graceful shutdown.
        }
    }

    private async Task RunDueSchedulesAsync(int maxRuns, CancellationToken cancellationToken)
    {
        IReadOnlyList<Guid> dueIds;
        await using (var scope = scopeFactory.CreateAsyncScope())
        {
            var repository = scope.ServiceProvider.GetRequiredService<IIngestionScheduleRepository>();
            dueIds = await repository.GetDueIdsAsync(timeProvider.GetUtcNow(), maxRuns, cancellationToken);
        }

        foreach (var scheduleId in dueIds)
        {
            var priceSourceId = await TryClaimAsync(scheduleId, cancellationToken);
            if (priceSourceId is null)
            {
                continue;
            }

            await using var scope = scopeFactory.CreateAsyncScope();
            var sender = scope.ServiceProvider.GetRequiredService<ISender>();

            try
            {
                var result = await sender.Send(
                    new RunIngestionJobCommand(priceSourceId.Value, IngestionTriggerType.Scheduled, null), cancellationToken);
                if (result.IsFailure)
                {
                    // e.g. the source was deactivated after it was scheduled.
                    LogRunRejected(logger, priceSourceId.Value, result.Error.Code, result.Error.Description);
                }
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                LogSourceFailed(logger, priceSourceId.Value, ex);
            }
        }
    }

    /// <summary>The source to run, or null when the slot is gone (claimed elsewhere, or edited since it was read).</summary>
    private async Task<Guid?> TryClaimAsync(Guid scheduleId, CancellationToken cancellationToken)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var sender = scope.ServiceProvider.GetRequiredService<ISender>();

        try
        {
            var claim = await sender.Send(new ClaimDueIngestionScheduleCommand(scheduleId), cancellationToken);
            return claim.IsSuccess ? claim.Value : null;
        }
        catch (DbUpdateConcurrencyException)
        {
            LogClaimLost(logger, scheduleId);
            return null;
        }
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Ingestion scheduler is disabled by configuration")]
    private static partial void LogDisabled(ILogger logger);

    [LoggerMessage(Level = LogLevel.Error, Message = "Ingestion scheduler tick failed")]
    private static partial void LogTickFailed(ILogger logger, Exception exception);

    [LoggerMessage(Level = LogLevel.Debug, Message = "Ingestion schedule {ScheduleId} was claimed by another instance")]
    private static partial void LogClaimLost(ILogger logger, Guid scheduleId);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Scheduled ingestion for source {PriceSourceId} was rejected: {Code} {Description}")]
    private static partial void LogRunRejected(ILogger logger, Guid priceSourceId, string code, string description);

    [LoggerMessage(Level = LogLevel.Error, Message = "Scheduled ingestion run failed for source {PriceSourceId}")]
    private static partial void LogSourceFailed(ILogger logger, Guid priceSourceId, Exception exception);
}
