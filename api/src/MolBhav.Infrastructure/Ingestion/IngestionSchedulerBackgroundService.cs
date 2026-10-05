using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Features.Ingestion.Admin.RunIngestionJob;
using MolBhav.Application.Features.Ingestion.Scheduling.ClaimDueIngestionSchedule;
using MolBhav.Application.Features.Weather.Admin.RunWeatherIngestionJob;
using MolBhav.Domain.Ingestion;
using MolBhav.Infrastructure.Weather;

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
    IOptions<ImdOptions> weatherOptions,
    TimeProvider timeProvider,
    ILogger<IngestionSchedulerBackgroundService> logger) : BackgroundService
{
    private DateTimeOffset _lastWeatherAttemptUtc = DateTimeOffset.MinValue;

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
                    await RunDueSchedulesAsync(settings.MaxRunsPerTick, settings.DataLagDays, stoppingToken);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    LogTickFailed(logger, ex);
                }

                // Separate from the price schedules so neither can block the other.
                try
                {
                    await RunWeatherIfDueAsync(stoppingToken);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    LogWeatherFailed(logger, ex);
                }
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Graceful shutdown.
        }
    }

    private async Task RunDueSchedulesAsync(int maxRuns, int dataLagDays, CancellationToken cancellationToken)
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
                    new RunIngestionJobCommand(
                        priceSourceId.Value,
                        IngestionTriggerType.Scheduled,
                        null,
                        IngestionDates.DefaultAsOf(timeProvider.GetUtcNow(), dataLagDays)),
                    cancellationToken);
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

    /// <summary>
    /// The daily weather refresh (per-user forecasts have no <c>PriceSource</c>/<c>IngestionSchedule</c> row). Once the IST
    /// run time has passed it sends the scheduled command at most every <see cref="ImdOptions.RetryAfterMinutes"/>; the
    /// command skips users who already hold today's forecast, so after a full success each attempt is a cheap no-op and
    /// a restart or second API instance never repeats work.
    /// </summary>
    private async Task RunWeatherIfDueAsync(CancellationToken cancellationToken)
    {
        var settings = weatherOptions.Value;
        if (!settings.ScheduleEnabled)
        {
            return;
        }

        var now = timeProvider.GetUtcNow();
        var runAt = TimeOnly.ParseExact(settings.DailyRunTimeIst, "HH:mm", System.Globalization.CultureInfo.InvariantCulture);
        if (TimeOnly.FromDateTime(now.ToOffset(IngestionSchedule.IstOffset).DateTime) < runAt
            || now - _lastWeatherAttemptUtc < TimeSpan.FromMinutes(settings.RetryAfterMinutes))
        {
            return;
        }

        _lastWeatherAttemptUtc = now;

        await using var scope = scopeFactory.CreateAsyncScope();
        var sender = scope.ServiceProvider.GetRequiredService<ISender>();
        var result = await sender.Send(new RunWeatherIngestionJobCommand(null, IngestionTriggerType.Scheduled), cancellationToken);

        if (result.IsFailure)
        {
            LogWeatherRejected(logger, result.Error.Code, result.Error.Description);
        }
        else if (result.Value.Refreshed > 0 || result.Value.Failed > 0)
        {
            LogWeatherRan(logger, result.Value.Refreshed, result.Value.Failed, result.Value.SkippedNoStation);
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

    [LoggerMessage(Level = LogLevel.Error, Message = "Scheduled weather refresh failed")]
    private static partial void LogWeatherFailed(ILogger logger, Exception exception);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Scheduled weather refresh was rejected: {Code} {Description}")]
    private static partial void LogWeatherRejected(ILogger logger, string code, string description);

    [LoggerMessage(Level = LogLevel.Information, Message = "Weather refresh: {Refreshed} refreshed, {Failed} failed, {NoStation} users without a mappable state")]
    private static partial void LogWeatherRan(ILogger logger, int refreshed, int failed, int noStation);

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
