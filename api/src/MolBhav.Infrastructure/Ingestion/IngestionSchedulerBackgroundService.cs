using MediatR;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Ingestion.Admin.RunIngestionJob;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Fulfils BRD §9/§18's "Background Services / scheduled workers" for ingestion: on <see cref="IngestionSchedulerOptions.IntervalHours"/>,
/// runs one <see cref="RunIngestionJobCommand"/> per active <c>PriceSource</c>. Each source's run gets its own DI
/// scope (own DbContext/transaction) so one failing source never blocks the rest, mirroring <c>OutboxProcessor</c>.
/// Until real adapters are wired up, every scheduled run ends up a <see cref="IngestionJobStatus.Failed"/> job with
/// an honest reason — this loop exists so the scheduling/observability plumbing is already in place when they are.
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

        using var timer = new PeriodicTimer(TimeSpan.FromHours(settings.IntervalHours), timeProvider);

        try
        {
            do
            {
                try
                {
                    await RunAllSourcesAsync(stoppingToken);
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

    private async Task RunAllSourcesAsync(CancellationToken cancellationToken)
    {
        IReadOnlyList<Domain.Pricing.PriceSource> sources;
        await using (var scope = scopeFactory.CreateAsyncScope())
        {
            var sourceRepository = scope.ServiceProvider.GetRequiredService<IPriceSourceRepository>();
            sources = await sourceRepository.GetActiveAsync(cancellationToken);
        }

        foreach (var source in sources)
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var sender = scope.ServiceProvider.GetRequiredService<ISender>();

            try
            {
                await sender.Send(new RunIngestionJobCommand(source.Id, IngestionTriggerType.Scheduled, null), cancellationToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                LogSourceFailed(logger, source.Code, ex);
            }
        }
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Ingestion scheduler is disabled by configuration")]
    private static partial void LogDisabled(ILogger logger);

    [LoggerMessage(Level = LogLevel.Error, Message = "Ingestion scheduler tick failed")]
    private static partial void LogTickFailed(ILogger logger, Exception exception);

    [LoggerMessage(Level = LogLevel.Error, Message = "Scheduled ingestion run failed for source {SourceCode}")]
    private static partial void LogSourceFailed(ILogger logger, string sourceCode, Exception exception);
}
