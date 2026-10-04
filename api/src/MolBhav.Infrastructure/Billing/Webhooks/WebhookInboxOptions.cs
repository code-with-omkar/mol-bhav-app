namespace MolBhav.Infrastructure.Billing.Webhooks;

public sealed class WebhookInboxOptions
{
    public const string SectionName = "WebhookInbox";

    public bool Enabled { get; set; } = true;

    public int PollingIntervalSeconds { get; set; } = 5;

    public int BatchSize { get; set; } = 20;

    /// <summary>After this many failed attempts a message is parked for manual review.</summary>
    public int MaxAttempts { get; set; } = 10;

    /// <summary>Delay before the first retry; doubles per attempt up to <see cref="MaxRetryDelaySeconds"/>.</summary>
    public int BaseRetryDelaySeconds { get; set; } = 30;

    public int MaxRetryDelaySeconds { get; set; } = 3600;

    /// <summary>Processed messages older than this are deleted by the daily purge. Parked messages are never purged.</summary>
    public int RetentionDays { get; set; } = 90;
}
