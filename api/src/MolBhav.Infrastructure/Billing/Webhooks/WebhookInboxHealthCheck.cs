using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;

namespace MolBhav.Infrastructure.Billing.Webhooks;

/// <summary>
/// Reports the webhook inbox from the processor's last snapshot (no database call per probe).
/// <para>
/// Deliberately never Unhealthy: this check is on the readiness endpoint, and taking an instance out of rotation
/// cannot fix a parked payment or a stalled worker. Degraded is served as HTTP 200 with body <c>Degraded</c>, so
/// monitoring can alert on it without the load balancer reacting; the reason and counts are in the health report.
/// </para>
/// Degraded when: the processor hasn't reported recently (stopped or disabled), a due message has waited past
/// <see cref="MaxOverdueLag"/> (processor falling behind), or anything was parked in the last 24 hours (a human
/// needs to look — often a refund).
/// </summary>
internal sealed class WebhookInboxHealthCheck(
    WebhookInboxMetrics metrics,
    IOptions<WebhookInboxOptions> options,
    TimeProvider timeProvider) : IHealthCheck
{
    public const string Name = "billing-webhook-inbox";

    internal static readonly TimeSpan MaxOverdueLag = TimeSpan.FromMinutes(2);

    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default) =>
        Task.FromResult(Evaluate(metrics.Stats, options.Value, timeProvider.GetUtcNow()));

    internal static HealthCheckResult Evaluate(WebhookInboxStats? stats, WebhookInboxOptions settings, DateTimeOffset nowUtc)
    {
        if (!settings.Enabled)
        {
            return HealthCheckResult.Degraded("Webhook inbox processor is disabled by configuration; webhooks are recorded but not applied.");
        }

        // Several refresh intervals of slack before calling the snapshot stale.
        var maxSnapshotAge = TimeSpan.FromSeconds(Math.Max(WebhookInboxProcessor.StatsRefreshInterval.TotalSeconds, settings.PollingIntervalSeconds) * 4);
        if (stats is null || nowUtc - stats.CapturedAtUtc > maxSnapshotAge)
        {
            return HealthCheckResult.Degraded("Webhook inbox processor has not reported recently.");
        }

        var data = new Dictionary<string, object>
        {
            ["pending"] = stats.Pending,
            ["overdueLagSeconds"] = Math.Round(stats.OverdueLagSeconds, 1),
            ["parked"] = stats.Parked,
            ["parkedLast24Hours"] = stats.ParkedLast24Hours,
            ["capturedAtUtc"] = stats.CapturedAtUtc,
        };

        if (stats.OverdueLagSeconds > MaxOverdueLag.TotalSeconds)
        {
            return HealthCheckResult.Degraded("Webhook inbox processor is falling behind.", data: data);
        }

        if (stats.ParkedLast24Hours > 0)
        {
            return HealthCheckResult.Degraded("Webhooks were parked in the last 24 hours and need review.", data: data);
        }

        return HealthCheckResult.Healthy("Webhook inbox is keeping up.", data);
    }
}
