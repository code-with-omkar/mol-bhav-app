namespace MolBhav.Application.Abstractions.Billing;

/// <summary>
/// Durable store for authenticated gateway webhooks. Recording is a single insert, so the gateway gets its 2xx well
/// inside its delivery timeout; the events are applied asynchronously, with retries and parking on failure.
/// </summary>
public interface IWebhookInbox
{
    /// <summary>
    /// Records the event unless one with the same <paramref name="provider"/> and <paramref name="eventId"/> already
    /// exists. Runs in the caller's unit of work.
    /// </summary>
    /// <returns><c>true</c> if the event was new; <c>false</c> for a redelivery.</returns>
    Task<bool> TryEnqueueAsync(
        string provider,
        string eventId,
        string eventType,
        string payload,
        CancellationToken cancellationToken);

    /// <summary>Puts a parked message back in the queue with a fresh attempt budget. Runs in the caller's unit of work.</summary>
    Task<WebhookRequeueResult> RequeueParkedAsync(Guid messageId, CancellationToken cancellationToken);
}

public enum WebhookRequeueResult
{
    Requeued = 0,
    NotFound = 1,

    /// <summary>Pending or already processed: only parked messages can be replayed.</summary>
    NotParked = 2,
}
