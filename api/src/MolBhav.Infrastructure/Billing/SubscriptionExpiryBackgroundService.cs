using MediatR;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Features.Billing.ExpireLapsed;

namespace MolBhav.Infrastructure.Billing;

/// <summary>
/// Periodically expires subscriptions whose paid period ended. Every batch runs in its own DI scope (own DbContext and
/// transaction), mirroring <c>OutboxProcessor</c>, so a failing batch never leaks partial writes and the next tick retries it.
/// </summary>
internal sealed partial class SubscriptionExpiryBackgroundService(
    IServiceScopeFactory scopeFactory,
    IOptions<SubscriptionExpiryOptions> options,
    TimeProvider timeProvider,
    ILogger<SubscriptionExpiryBackgroundService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var settings = options.Value;

        if (!settings.Enabled)
        {
            LogDisabled(logger);
            return;
        }

        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(settings.IntervalMinutes), timeProvider);

        try
        {
            do
            {
                try
                {
                    int expired;
                    do
                    {
                        expired = await ExpireBatchAsync(settings.BatchSize, stoppingToken);
                    }
                    while (expired == settings.BatchSize && !stoppingToken.IsCancellationRequested); // drain backlog before sleeping
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

    private async Task<int> ExpireBatchAsync(int batchSize, CancellationToken cancellationToken)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var sender = scope.ServiceProvider.GetRequiredService<ISender>();

        var result = await sender.Send(new ExpireLapsedSubscriptionsCommand(batchSize), cancellationToken);
        if (result.IsFailure)
        {
            LogBatchRejected(logger, result.Error.Code);
            return 0;
        }

        return result.Value;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Subscription expiry sweep is disabled by configuration")]
    private static partial void LogDisabled(ILogger logger);

    [LoggerMessage(Level = LogLevel.Error, Message = "Subscription expiry sweep failed")]
    private static partial void LogTickFailed(ILogger logger, Exception exception);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Subscription expiry batch was rejected: {ErrorCode}")]
    private static partial void LogBatchRejected(ILogger logger, string errorCode);
}
