using Microsoft.Extensions.Diagnostics.HealthChecks;
using MolBhav.Infrastructure.Billing.Webhooks;

namespace MolBhav.UnitTests.Billing;

public sealed class WebhookInboxHealthCheckTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 4, 12, 0, 0, TimeSpan.Zero);
    private static readonly WebhookInboxOptions Settings = new();

    private static WebhookInboxStats Stats(double overdueLagSeconds = 0, long parkedLast24Hours = 0, DateTimeOffset? capturedAt = null) =>
        new(Pending: 3, overdueLagSeconds, Parked: parkedLast24Hours, parkedLast24Hours, capturedAt ?? Now.AddSeconds(-10));

    [Fact]
    public void Evaluate_KeepingUp_IsHealthy()
    {
        var result = WebhookInboxHealthCheck.Evaluate(Stats(overdueLagSeconds: 5), Settings, Now);

        Assert.Equal(HealthStatus.Healthy, result.Status);
        Assert.Equal(3L, result.Data["pending"]);
    }

    [Fact]
    public void Evaluate_NoSnapshotYet_IsDegraded()
    {
        Assert.Equal(HealthStatus.Degraded, WebhookInboxHealthCheck.Evaluate(null, Settings, Now).Status);
    }

    [Fact]
    public void Evaluate_StaleSnapshot_IsDegraded()
    {
        var result = WebhookInboxHealthCheck.Evaluate(Stats(capturedAt: Now.AddMinutes(-10)), Settings, Now);

        Assert.Equal(HealthStatus.Degraded, result.Status);
    }

    [Fact]
    public void Evaluate_FallingBehind_IsDegraded()
    {
        var result = WebhookInboxHealthCheck.Evaluate(
            Stats(overdueLagSeconds: WebhookInboxHealthCheck.MaxOverdueLag.TotalSeconds + 1), Settings, Now);

        Assert.Equal(HealthStatus.Degraded, result.Status);
    }

    [Fact]
    public void Evaluate_ParkedRecently_IsDegraded()
    {
        var result = WebhookInboxHealthCheck.Evaluate(Stats(parkedLast24Hours: 1), Settings, Now);

        Assert.Equal(HealthStatus.Degraded, result.Status);
    }

    [Fact]
    public void Evaluate_ProcessorDisabled_IsDegraded()
    {
        var result = WebhookInboxHealthCheck.Evaluate(Stats(), new WebhookInboxOptions { Enabled = false }, Now);

        Assert.Equal(HealthStatus.Degraded, result.Status);
    }

    [Fact]
    public void Evaluate_NeverUnhealthy_SoReadinessNeverPullsTheInstance()
    {
        var worst = WebhookInboxHealthCheck.Evaluate(Stats(overdueLagSeconds: 86_400, parkedLast24Hours: 50), Settings, Now);

        Assert.NotEqual(HealthStatus.Unhealthy, worst.Status);
    }
}
