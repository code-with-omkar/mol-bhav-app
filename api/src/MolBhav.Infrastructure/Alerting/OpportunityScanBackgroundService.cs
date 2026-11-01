using MediatR;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Features.Alerting.Opportunities.ScanMarketOpportunities;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Infrastructure.Alerting;

/// <summary>
/// Runs the market-opportunity scan once per IST day, after <see cref="OpportunityOptions.DailyRunTimeIst"/>. The scan
/// itself never creates a second opportunity for a user/product on the same day, so a restart or a second API
/// instance repeating it is harmless; a failed attempt is retried on the next poll.
/// </summary>
internal sealed partial class OpportunityScanBackgroundService(
    IServiceScopeFactory scopeFactory,
    IOptions<OpportunityOptions> options,
    TimeProvider timeProvider,
    ILogger<OpportunityScanBackgroundService> logger) : BackgroundService
{
    private DateOnly _lastRunOn = DateOnly.MinValue;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var settings = options.Value;
        if (!settings.Enabled || !settings.TryGetRunTime(out var runAt))
        {
            LogDisabled(logger);
            return;
        }

        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(settings.PollMinutes), timeProvider);

        try
        {
            do
            {
                var nowUtc = timeProvider.GetUtcNow();
                var nowIst = nowUtc.ToOffset(IngestionSchedule.IstOffset);
                var today = IngestionDates.TodayIst(nowUtc);
                if (_lastRunOn == today || TimeOnly.FromDateTime(nowIst.DateTime) < runAt)
                {
                    continue;
                }

                try
                {
                    await using var scope = scopeFactory.CreateAsyncScope();
                    var sender = scope.ServiceProvider.GetRequiredService<ISender>();
                    var result = await sender.Send(new ScanMarketOpportunitiesCommand(), stoppingToken);
                    if (result.IsSuccess)
                    {
                        _lastRunOn = today;
                    }
                    else
                    {
                        LogRejected(logger, result.Error.Code);
                    }
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    LogFailed(logger, ex);
                }
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Graceful shutdown.
        }
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Daily opportunity scan is disabled by configuration")]
    private static partial void LogDisabled(ILogger logger);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Opportunity scan was rejected: {ErrorCode}")]
    private static partial void LogRejected(ILogger logger, string errorCode);

    [LoggerMessage(Level = LogLevel.Error, Message = "Opportunity scan failed")]
    private static partial void LogFailed(ILogger logger, Exception exception);
}
