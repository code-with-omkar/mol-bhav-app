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
}
