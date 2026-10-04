namespace MolBhav.Infrastructure.Billing.Webhooks;

/// <summary>
/// A payment-gateway webhook, stored verbatim the moment its signature verifies and processed later by
/// <see cref="WebhookInboxProcessor"/>. Acknowledging only after this row commits means Razorpay never needs to
/// redeliver an event we accepted, and processing failures become rows we can retry, inspect and replay instead of
/// lost requests.
/// <para>States: pending (neither timestamp set) → processed, or → parked (needs a human; never retried automatically).</para>
/// </summary>
public sealed class WebhookInboxMessage
{
    public const int ProviderMaxLength = 30;
    public const int EventIdMaxLength = 100;
    public const int EventTypeMaxLength = 100;
    public const int ErrorMaxLength = 2000;

    private WebhookInboxMessage()
    {
    }

    public Guid Id { get; private set; }

    /// <summary>Gateway the event came from (e.g. <c>razorpay</c>); unique together with <see cref="EventId"/>.</summary>
    public string Provider { get; private set; } = string.Empty;

    /// <summary>The gateway's own event id (<c>x-razorpay-event-id</c>) — the deduplication key across redeliveries.</summary>
    public string EventId { get; private set; } = string.Empty;

    public string EventType { get; private set; } = string.Empty;

    /// <summary>Raw request body exactly as signed by the gateway (jsonb).</summary>
    public string Payload { get; private set; } = string.Empty;

    public DateTimeOffset ReceivedAtUtc { get; private set; }

    /// <summary>Earliest time the processor may pick this message up again (exponential backoff after failures).</summary>
    public DateTimeOffset NextAttemptAtUtc { get; private set; }

    public int AttemptCount { get; private set; }

    public DateTimeOffset? LastAttemptAtUtc { get; private set; }

    public string? LastError { get; private set; }

    public DateTimeOffset? ProcessedAtUtc { get; private set; }

    /// <summary>Set when retrying cannot help (bad payload, business conflict, attempts exhausted).</summary>
    public DateTimeOffset? ParkedAtUtc { get; private set; }

    public void MarkProcessed(DateTimeOffset nowUtc)
    {
        EnsurePending();

        AttemptCount++;
        LastAttemptAtUtc = nowUtc;
        ProcessedAtUtc = nowUtc;
        LastError = null;
    }

    /// <summary>Records a failed attempt that may succeed later.</summary>
    public void ScheduleRetry(string error, DateTimeOffset nowUtc, DateTimeOffset nextAttemptAtUtc)
    {
        EnsurePending();

        if (nextAttemptAtUtc < nowUtc)
        {
            throw new ArgumentOutOfRangeException(nameof(nextAttemptAtUtc), "The next attempt cannot be in the past.");
        }

        AttemptCount++;
        LastAttemptAtUtc = nowUtc;
        NextAttemptAtUtc = nextAttemptAtUtc;
        LastError = Truncate(error);
    }

    /// <summary>Records a failed attempt and stops automatic retries.</summary>
    public void Park(string error, DateTimeOffset nowUtc)
    {
        EnsurePending();

        AttemptCount++;
        LastAttemptAtUtc = nowUtc;
        ParkedAtUtc = nowUtc;
        LastError = Truncate(error);
    }

    private void EnsurePending()
    {
        if (ProcessedAtUtc is not null || ParkedAtUtc is not null)
        {
            throw new InvalidOperationException($"Webhook inbox message {Id} is no longer pending.");
        }
    }

    private static string Truncate(string error) => error.Length <= ErrorMaxLength ? error : error[..ErrorMaxLength];
}
