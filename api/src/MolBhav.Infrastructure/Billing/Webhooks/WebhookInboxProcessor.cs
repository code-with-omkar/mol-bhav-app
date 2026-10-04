using System.Diagnostics;
using System.Globalization;
using System.Security.Cryptography;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Application.Features.Billing.Webhook;
using MolBhav.Domain.Common.Results;
using MolBhav.Infrastructure.Persistence;

namespace MolBhav.Infrastructure.Billing.Webhooks;

/// <summary>
/// Applies queued gateway webhooks. Same shape as the outbox processor:
/// <list type="bullet">
/// <item><c>FOR UPDATE SKIP LOCKED</c> lets several API instances poll concurrently without double-processing; the row
/// locks live as long as the batch transaction, so a crashed instance simply releases them.</item>
/// <item>Each message is applied in its own DI scope (own DbContext and unit-of-work transaction): one failing event
/// never leaks partial writes into another or into the inbox bookkeeping.</item>
/// <item>At-least-once: if the bookkeeping commit fails after a command committed, the command runs again — webhook
/// commands are idempotent (activation is a no-op for the same payment).</item>
/// </list>
/// Failures are classified: those a retry can fix are rescheduled with exponential backoff; those it can't (unreadable
/// payload, a payment that conflicts with the subscription's state) are parked at once, as are messages that run out
/// of attempts. Parked messages need a human (often a refund): they are logged at Critical and, once the batch has
/// committed, sent to <see cref="IOpsAlertSender"/>.
/// <para>Between polls it refreshes the <see cref="WebhookInboxStats"/> snapshot (metrics and health check) and, once
/// a day, purges processed messages past <see cref="WebhookInboxOptions.RetentionDays"/>.</para>
/// </summary>
internal sealed partial class WebhookInboxProcessor(
    IServiceScopeFactory scopeFactory,
    IOptions<WebhookInboxOptions> options,
    WebhookInboxMetrics metrics,
    WebhookInboxStatsReader statsReader,
    IOpsAlertSender opsAlerts,
    TimeProvider timeProvider,
    ILogger<WebhookInboxProcessor> logger) : BackgroundService
{
    internal static readonly TimeSpan StatsRefreshInterval = TimeSpan.FromSeconds(30);

    private static readonly TimeSpan PurgeInterval = TimeSpan.FromDays(1);
    private const int PurgeBatchSize = 1000;

    // Identifier comes from a compile-time constant (never user input); values are bound as parameters.
    private const string LockBatchSql =
        "SELECT * FROM " + WebhookInboxMessageConfiguration.QualifiedTableName +
        " WHERE processed_at_utc IS NULL AND parked_at_utc IS NULL AND next_attempt_at_utc <= {0}" +
        " ORDER BY next_attempt_at_utc" +
        " LIMIT {1}" +
        " FOR UPDATE SKIP LOCKED";

    private const string PurgeSql =
        "DELETE FROM " + WebhookInboxMessageConfiguration.QualifiedTableName +
        " WHERE id IN (SELECT id FROM " + WebhookInboxMessageConfiguration.QualifiedTableName +
        " WHERE processed_at_utc < {0} ORDER BY processed_at_utc LIMIT {1})";

    private DateTimeOffset _lastStatsRefreshUtc = DateTimeOffset.MinValue;
    private DateTimeOffset _lastPurgeUtc = DateTimeOffset.MinValue;

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

                await RunHousekeepingAsync(settings, stoppingToken);
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Graceful shutdown.
        }
    }

    private async Task<int> ProcessBatchAsync(WebhookInboxOptions settings, CancellationToken cancellationToken)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<MolBhavDbContext>();
        var strategy = dbContext.Database.CreateExecutionStrategy();
        var parked = new List<WebhookInboxMessage>();

        var count = await strategy.ExecuteAsync(
            async token =>
            {
                dbContext.ChangeTracker.Clear();
                parked.Clear();

                await using var transaction = await dbContext.Database.BeginTransactionAsync(token);

                var messages = await dbContext.Set<WebhookInboxMessage>()
                    .FromSqlRaw(LockBatchSql, timeProvider.GetUtcNow(), settings.BatchSize)
                    .ToListAsync(token);

                foreach (var message in messages)
                {
                    await ProcessMessageAsync(message, settings, token);

                    if (message.ParkedAtUtc is not null)
                    {
                        parked.Add(message);
                    }
                }

                await dbContext.SaveChangesAsync(token);
                await transaction.CommitAsync(token);

                return messages.Count;
            },
            cancellationToken);

        // Only after the commit: an alert must describe a park that actually happened.
        foreach (var message in parked)
        {
            await opsAlerts.SendAsync(ParkedAlert(message), cancellationToken);
        }

        return count;
    }

    private async Task ProcessMessageAsync(WebhookInboxMessage message, WebhookInboxOptions settings, CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();

        if (!RazorpayWebhookPayload.TryParse(message.Payload, out var command))
        {
            Park(message, "Payload has no readable event.", stopwatch);
            return;
        }

        try
        {
            await using var handlerScope = scopeFactory.CreateAsyncScope();
            var sender = handlerScope.ServiceProvider.GetRequiredService<ISender>();
            var result = await sender.Send(command, cancellationToken);

            if (result.IsSuccess)
            {
                message.MarkProcessed(timeProvider.GetUtcNow());
                metrics.RecordAttempt(message.EventType, WebhookInboxMetrics.OutcomeProcessed, stopwatch.Elapsed.TotalMilliseconds);
                LogProcessed(logger, message.Id, message.EventId, message.EventType, message.AttemptCount);
                return;
            }

            var error = $"{result.Error.Code}: {result.Error.Description}";
            if (IsRetryable(result.Error))
            {
                Retry(message, settings, error, exception: null, stopwatch);
            }
            else
            {
                Park(message, error, stopwatch);
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            // Unexpected failures (database blips, a concurrency conflict with the client activate call) are retried:
            // the next attempt sees the committed state and either no-ops or reports a classified failure.
            Retry(message, settings, ex.ToString(), ex, stopwatch);
        }
    }

    /// <summary>
    /// Not found: the order may not be committed yet. Unavailable / unclassified: a dependency failed.
    /// Everything else (validation, conflict, business rule) describes the data, which a retry won't change.
    /// </summary>
    private static bool IsRetryable(Error error) =>
        error.Type is ErrorType.NotFound or ErrorType.Unavailable or ErrorType.Failure;

    private void Retry(WebhookInboxMessage message, WebhookInboxOptions settings, string error, Exception? exception, Stopwatch stopwatch)
    {
        if (message.AttemptCount + 1 >= settings.MaxAttempts)
        {
            Park(message, error, stopwatch);
            return;
        }

        var nowUtc = timeProvider.GetUtcNow();
        var nextAttemptAtUtc = nowUtc + RetryDelay(message.AttemptCount + 1, settings);
        message.ScheduleRetry(error, nowUtc, nextAttemptAtUtc);

        metrics.RecordAttempt(message.EventType, WebhookInboxMetrics.OutcomeRetry, stopwatch.Elapsed.TotalMilliseconds);
        LogRetryScheduled(logger, message.Id, message.EventId, message.EventType, message.AttemptCount, nextAttemptAtUtc, error, exception);
    }

    private void Park(WebhookInboxMessage message, string error, Stopwatch stopwatch)
    {
        message.Park(error, timeProvider.GetUtcNow());
        metrics.RecordAttempt(message.EventType, WebhookInboxMetrics.OutcomeParked, stopwatch.Elapsed.TotalMilliseconds);
        LogParked(logger, message.Id, message.EventId, message.EventType, message.AttemptCount, error);
    }

    private static OpsAlert ParkedAlert(WebhookInboxMessage message)
    {
        var error = message.LastError ?? string.Empty;

        // The first line is the classified reason; exception stack traces stay in the logs.
        var reason = error.Split('\n', 2)[0];

        return new OpsAlert(
            "Payment webhook parked — needs manual review",
            [
                new("Event", $"{message.EventType} ({message.EventId})"),
                new("Provider", message.Provider),
                new("Inbox message", message.Id.ToString()),
                new("Attempts", message.AttemptCount.ToString(CultureInfo.InvariantCulture)),
                new("Reason", reason.Length <= 300 ? reason : reason[..300]),
                new("Next step", "Fix the cause (or refund), then POST /api/v1/admin/billing/webhooks/{id}/replay"),
            ]);
    }

    /// <summary>
    /// Exponential backoff with ±20 % jitter: base × 2^(attempt−1), capped. Jitter spreads retries of events that
    /// failed together (e.g. during a database outage) so they don't all come back in the same poll.
    /// </summary>
    private static TimeSpan RetryDelay(int attempt, WebhookInboxOptions settings)
    {
        var exponential = settings.BaseRetryDelaySeconds * Math.Pow(2, Math.Min(attempt - 1, 30));
        var capped = Math.Min(exponential, settings.MaxRetryDelaySeconds);

        // RandomNumberGenerator only to stay clear of the insecure-randomness analyzer; nothing here is security-sensitive.
        var jitterFactor = 0.8 + (RandomNumberGenerator.GetInt32(0, 401) / 1000.0);
        return TimeSpan.FromSeconds(capped * jitterFactor);
    }

    /// <summary>Stats snapshot (every <see cref="StatsRefreshInterval"/>) and retention purge (daily). Never throws.</summary>
    private async Task RunHousekeepingAsync(WebhookInboxOptions settings, CancellationToken cancellationToken)
    {
        var nowUtc = timeProvider.GetUtcNow();

        if (nowUtc - _lastStatsRefreshUtc >= StatsRefreshInterval)
        {
            try
            {
                metrics.Update(await statsReader.ReadAsync(cancellationToken));
                _lastStatsRefreshUtc = nowUtc;
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                LogStatsFailed(logger, ex);
            }
        }

        if (nowUtc - _lastPurgeUtc >= PurgeInterval)
        {
            try
            {
                var purged = await PurgeProcessedAsync(nowUtc.AddDays(-settings.RetentionDays), cancellationToken);
                _lastPurgeUtc = nowUtc;

                if (purged > 0)
                {
                    LogPurged(logger, purged, settings.RetentionDays);
                }
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                LogPurgeFailed(logger, ex);
            }
        }
    }

    /// <summary>Deletes in small batches (each its own statement) so the purge never holds long locks.</summary>
    private async Task<int> PurgeProcessedAsync(DateTimeOffset processedBeforeUtc, CancellationToken cancellationToken)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<MolBhavDbContext>();

        var total = 0;
        int deleted;
        do
        {
            deleted = await dbContext.Database.ExecuteSqlRawAsync(
                PurgeSql, new object[] { processedBeforeUtc, PurgeBatchSize }, cancellationToken);
            total += deleted;
        }
        while (deleted == PurgeBatchSize && !cancellationToken.IsCancellationRequested);

        return total;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Webhook inbox processor is disabled by configuration")]
    private static partial void LogDisabled(ILogger logger);

    [LoggerMessage(Level = LogLevel.Error, Message = "Webhook inbox batch failed")]
    private static partial void LogBatchFailed(ILogger logger, Exception exception);

    [LoggerMessage(Level = LogLevel.Information, Message = "Webhook {MessageId} ({EventId}, {EventType}) applied on attempt {Attempt}")]
    private static partial void LogProcessed(ILogger logger, Guid messageId, string eventId, string eventType, int attempt);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Webhook {MessageId} ({EventId}, {EventType}) failed on attempt {Attempt}; retrying at {NextAttemptAtUtc}: {Error}")]
    private static partial void LogRetryScheduled(
        ILogger logger, Guid messageId, string eventId, string eventType, int attempt, DateTimeOffset nextAttemptAtUtc, string error, Exception? exception);

    [LoggerMessage(Level = LogLevel.Critical, Message = "Webhook {MessageId} ({EventId}, {EventType}) parked after {Attempt} attempt(s); needs manual review: {Error}")]
    private static partial void LogParked(ILogger logger, Guid messageId, string eventId, string eventType, int attempt, string error);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Webhook inbox stats refresh failed")]
    private static partial void LogStatsFailed(ILogger logger, Exception exception);

    [LoggerMessage(Level = LogLevel.Information, Message = "Webhook inbox purge deleted {Count} processed message(s) older than {RetentionDays} days")]
    private static partial void LogPurged(ILogger logger, int count, int retentionDays);

    [LoggerMessage(Level = LogLevel.Error, Message = "Webhook inbox purge failed")]
    private static partial void LogPurgeFailed(ILogger logger, Exception exception);
}
