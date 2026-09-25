namespace MolBhav.Infrastructure.Messaging.Outbox;

/// <summary>
/// A domain event persisted in the same transaction as the aggregate that raised it
/// (guarantees no alert/notification is lost if the process dies after commit).
/// </summary>
public sealed class OutboxMessage
{
    public const int TypeMaxLength = 512;
    public const int ErrorMaxLength = 2000;

    private OutboxMessage()
    {
    }

    /// <summary>Equals the domain event's EventId — gives handlers a natural idempotency key.</summary>
    public Guid Id { get; private set; }

    public DateTimeOffset OccurredAtUtc { get; private set; }

    public string Type { get; private set; } = string.Empty;

    public string Content { get; private set; } = string.Empty;

    public DateTimeOffset? ProcessedAtUtc { get; private set; }

    public int AttemptCount { get; private set; }

    public DateTimeOffset? LastAttemptAtUtc { get; private set; }

    public string? LastError { get; private set; }

    public static OutboxMessage Create(Guid eventId, DateTimeOffset occurredAtUtc, string type, string content)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(type);
        ArgumentException.ThrowIfNullOrWhiteSpace(content);

        return new OutboxMessage
        {
            Id = eventId,
            OccurredAtUtc = occurredAtUtc,
            Type = type,
            Content = content,
        };
    }

    public void MarkProcessed(DateTimeOffset nowUtc)
    {
        AttemptCount++;
        LastAttemptAtUtc = nowUtc;
        ProcessedAtUtc = nowUtc;
        LastError = null;
    }

    public void MarkFailed(string error, DateTimeOffset nowUtc)
    {
        AttemptCount++;
        LastAttemptAtUtc = nowUtc;
        LastError = error.Length <= ErrorMaxLength ? error : error[..ErrorMaxLength];
    }
}
