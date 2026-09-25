using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Infrastructure.Persistence;

namespace MolBhav.Infrastructure.Messaging.Outbox;

/// <summary>
/// Polls the outbox and dispatches events to <c>IDomainEventHandler</c>s.
/// <list type="bullet">
/// <item><c>FOR UPDATE SKIP LOCKED</c> lets several API instances poll concurrently without double-processing.</item>
/// <item>Each message is dispatched in its own DI scope (own DbContext/unit of work): one failing handler never
/// leaks partial writes into another message or into the outbox bookkeeping.</item>
/// <item>At-least-once: if the bookkeeping commit fails after handlers ran, they run again — handlers must be idempotent.</item>
/// </list>
/// </summary>
internal sealed partial class OutboxProcessor(
    IServiceScopeFactory scopeFactory,
    IOptions<OutboxOptions> options,
    TimeProvider timeProvider,
    ILogger<OutboxProcessor> logger) : BackgroundService
{
    // Identifier comes from a compile-time constant (never user input); values are bound as parameters.
    private const string LockBatchSql =
        "SELECT * FROM " + OutboxMessageConfiguration.QualifiedTableName +
        " WHERE processed_at_utc IS NULL AND attempt_count < {0}" +
        " ORDER BY occurred_at_utc" +
        " LIMIT {1}" +
        " FOR UPDATE SKIP LOCKED";

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var settings = options.Value;

        if (!settings.Enabled)
        {
            LogDisabled(logger);
            return;
        }

        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(settings.PollingIntervalSeconds), timeProvider);

        try
        {
            do
            {
                try
                {
                    int processed;
                    do
                    {
                        processed = await ProcessBatchAsync(settings, stoppingToken);
                    }
                    while (processed == settings.BatchSize && !stoppingToken.IsCancellationRequested); // drain backlog before sleeping
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    LogBatchFailed(logger, ex);
                }
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Graceful shutdown.
        }
    }

    private async Task<int> ProcessBatchAsync(OutboxOptions settings, CancellationToken cancellationToken)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<MolBhavDbContext>();
        var strategy = dbContext.Database.CreateExecutionStrategy();

        return await strategy.ExecuteAsync(
            async token =>
            {
                dbContext.ChangeTracker.Clear();

                await using var transaction = await dbContext.Database.BeginTransactionAsync(token);

                var messages = await dbContext.Set<OutboxMessage>()
                    .FromSqlRaw(LockBatchSql, settings.MaxAttempts, settings.BatchSize)
                    .ToListAsync(token);

                foreach (var message in messages)
                {
                    await ProcessMessageAsync(message, settings, token);
                }

                await dbContext.SaveChangesAsync(token);
                await transaction.CommitAsync(token);

                return messages.Count;
            },
            cancellationToken);
    }

    private async Task ProcessMessageAsync(OutboxMessage message, OutboxOptions settings, CancellationToken cancellationToken)
    {
        try
        {
            var domainEvent = DomainEventSerializer.Deserialize(message.Type, message.Content);

            await using var handlerScope = scopeFactory.CreateAsyncScope();
            var dispatcher = handlerScope.ServiceProvider.GetRequiredService<DomainEventDispatcher>();
            await dispatcher.DispatchAsync(domainEvent, cancellationToken);

            message.MarkProcessed(timeProvider.GetUtcNow());
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            message.MarkFailed(ex.ToString(), timeProvider.GetUtcNow());

            if (message.AttemptCount >= settings.MaxAttempts)
            {
                LogMessageParked(logger, message.Id, message.Type, message.AttemptCount, ex);
            }
            else
            {
                LogMessageFailed(logger, message.Id, message.Type, message.AttemptCount, ex);
            }
        }
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Outbox processor is disabled by configuration")]
    private static partial void LogDisabled(ILogger logger);

    [LoggerMessage(Level = LogLevel.Error, Message = "Outbox batch failed")]
    private static partial void LogBatchFailed(ILogger logger, Exception exception);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Outbox message {MessageId} ({MessageType}) failed on attempt {Attempt}")]
    private static partial void LogMessageFailed(ILogger logger, Guid messageId, string messageType, int attempt, Exception exception);

    [LoggerMessage(Level = LogLevel.Critical, Message = "Outbox message {MessageId} ({MessageType}) parked after {Attempt} attempts")]
    private static partial void LogMessageParked(ILogger logger, Guid messageId, string messageType, int attempt, Exception exception);
}
