using System.Diagnostics.Metrics;

namespace MolBhav.Infrastructure.Billing.Webhooks;

/// <summary>A point-in-time view of the webhook inbox, refreshed by <see cref="WebhookInboxProcessor"/>.</summary>
/// <param name="Pending">Messages not yet processed or parked (including ones waiting out a retry backoff).</param>
/// <param name="OverdueLagSeconds">How long the most overdue pending message has been due; 0 when nothing is due.
/// Measures processor health — a message waiting for its next backoff slot is not overdue.</param>
/// <param name="Parked">Parked messages awaiting manual review.</param>
/// <param name="ParkedLast24Hours">Messages parked in the last 24 hours.</param>
/// <param name="CapturedAtUtc">When the snapshot was taken; a stale snapshot means the processor stopped reporting.</param>
public sealed record WebhookInboxStats(long Pending, double OverdueLagSeconds, long Parked, long ParkedLast24Hours, DateTimeOffset CapturedAtUtc);

/// <summary>
/// Meter <c>MolBhav.Billing.Webhooks</c> (System.Diagnostics.Metrics — exportable via OpenTelemetry or
/// <c>dotnet-counters monitor --counters MolBhav.Billing.Webhooks</c> with no code change).
/// Gauges read the last <see cref="WebhookInboxStats"/> snapshot, so scraping never touches the database.
/// </summary>
public sealed class WebhookInboxMetrics
{
    public const string MeterName = "MolBhav.Billing.Webhooks";

    public const string OutcomeProcessed = "processed";
    public const string OutcomeRetry = "retry";
    public const string OutcomeParked = "parked";

    private readonly Counter<long> _received;
    private readonly Counter<long> _processed;
    private readonly Histogram<double> _duration;
    private volatile WebhookInboxStats? _stats;

    public WebhookInboxMetrics(IMeterFactory meterFactory)
    {
        ArgumentNullException.ThrowIfNull(meterFactory);

        var meter = meterFactory.Create(MeterName);

        _received = meter.CreateCounter<long>(
            "molbhav.billing.webhooks.received", "{event}", "Authenticated webhooks recorded (or recognised as redeliveries).");
        _processed = meter.CreateCounter<long>(
            "molbhav.billing.webhooks.processed", "{attempt}", "Processing attempts by outcome: processed, retry, parked.");
        _duration = meter.CreateHistogram<double>(
            "molbhav.billing.webhooks.processing.duration", "ms", "Time to apply one webhook, by outcome.");

        meter.CreateObservableGauge(
            "molbhav.billing.webhooks.pending", () => _stats?.Pending ?? 0, "{event}", "Webhooks not yet processed or parked.");
        meter.CreateObservableGauge(
            "molbhav.billing.webhooks.overdue_lag", () => _stats?.OverdueLagSeconds ?? 0, "s", "How long the most overdue pending webhook has been due.");
        meter.CreateObservableGauge(
            "molbhav.billing.webhooks.parked", () => _stats?.Parked ?? 0, "{event}", "Parked webhooks awaiting manual review.");
    }

    /// <summary>The last snapshot, or <c>null</c> before the processor has reported once.</summary>
    public WebhookInboxStats? Stats => _stats;

    public void RecordReceived(string eventType, bool duplicate) =>
        _received.Add(1, new KeyValuePair<string, object?>("event_type", eventType), new KeyValuePair<string, object?>("duplicate", duplicate));

    public void RecordAttempt(string eventType, string outcome, double durationMs)
    {
        var eventTypeTag = new KeyValuePair<string, object?>("event_type", eventType);
        var outcomeTag = new KeyValuePair<string, object?>("outcome", outcome);

        _processed.Add(1, eventTypeTag, outcomeTag);
        _duration.Record(durationMs, eventTypeTag, outcomeTag);
    }

    public void Update(WebhookInboxStats stats) => _stats = stats;
}
