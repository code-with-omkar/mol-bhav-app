using MediatR;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Features.Billing.ReconcilePayments;

namespace MolBhav.Infrastructure.Billing;

/// <summary>
/// Periodically asks the gateway whether pending-payment orders were paid, activating any whose webhook never arrived
/// (lost, rejected, or Razorpay auto-disabled the webhook after repeated failures). Webhooks stay the fast path; this
/// is the safety net. Each subscription is reconciled in its own DI scope (own DbContext and transaction), mirroring
/// <c>SubscriptionExpiryBackgroundService</c>, so one failure never blocks or leaks into the others.
/// </summary>
internal sealed partial class PaymentReconciliationBackgroundService(
    IServiceScopeFactory scopeFactory,
    IOptions<PaymentReconciliationOptions> options,
    TimeProvider timeProvider,
    ILogger<PaymentReconciliationBackgroundService> logger) : BackgroundService
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
                    await SweepAsync(settings, stoppingToken);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    LogSweepFailed(logger, ex);
                }
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Graceful shutdown.
        }
    }

    private async Task SweepAsync(PaymentReconciliationOptions settings, CancellationToken cancellationToken)
    {
        var nowUtc = timeProvider.GetUtcNow();

        IReadOnlyList<Guid> candidates;
        await using (var scope = scopeFactory.CreateAsyncScope())
        {
            var sender = scope.ServiceProvider.GetRequiredService<ISender>();
            var listed = await sender.Send(
                new ListPendingPaymentsToReconcileQuery(
                    nowUtc.AddHours(-settings.MaxAgeHours), nowUtc.AddMinutes(-settings.MinAgeMinutes), settings.BatchSize),
                cancellationToken);

            if (listed.IsFailure)
            {
                LogListRejected(logger, listed.Error.Code);
                return;
            }

            candidates = listed.Value;
        }

        var activated = 0;
        foreach (var subscriptionId in candidates)
        {
            cancellationToken.ThrowIfCancellationRequested();

            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var sender = scope.ServiceProvider.GetRequiredService<ISender>();
                var result = await sender.Send(new ReconcilePendingPaymentCommand(subscriptionId), cancellationToken);

                if (result.IsFailure)
                {
                    LogReconcileRejected(logger, subscriptionId, result.Error.Code);
                }
                else if (result.Value == PaymentReconciliationOutcome.Activated)
                {
                    activated++;
                }
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                // E.g. a concurrency conflict with the webhook activating the same subscription: the next sweep sees it
                // as no longer pending.
                LogReconcileFailed(logger, subscriptionId, ex);
            }
        }

        if (candidates.Count > 0)
        {
            LogSwept(logger, candidates.Count, activated);
        }
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Payment reconciliation is disabled by configuration")]
    private static partial void LogDisabled(ILogger logger);

    [LoggerMessage(Level = LogLevel.Error, Message = "Payment reconciliation sweep failed")]
    private static partial void LogSweepFailed(ILogger logger, Exception exception);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Payment reconciliation candidate listing was rejected: {ErrorCode}")]
    private static partial void LogListRejected(ILogger logger, string errorCode);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Payment reconciliation for subscription {SubscriptionId} did not complete: {ErrorCode}")]
    private static partial void LogReconcileRejected(ILogger logger, Guid subscriptionId, string errorCode);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Payment reconciliation for subscription {SubscriptionId} failed")]
    private static partial void LogReconcileFailed(ILogger logger, Guid subscriptionId, Exception exception);

    [LoggerMessage(Level = LogLevel.Information, Message = "Payment reconciliation checked {CheckedCount} pending order(s); activated {ActivatedCount}")]
    private static partial void LogSwept(ILogger logger, int checkedCount, int activatedCount);
}
