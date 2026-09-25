namespace MolBhav.Infrastructure.Messaging.Outbox;

public sealed class OutboxOptions
{
    public const string SectionName = "Outbox";

    public bool Enabled { get; set; } = true;

    public int PollingIntervalSeconds { get; set; } = 5;

    public int BatchSize { get; set; } = 50;

    /// <summary>After this many failed attempts a message is parked (left unprocessed with its last error) for manual review.</summary>
    public int MaxAttempts { get; set; } = 5;
}
