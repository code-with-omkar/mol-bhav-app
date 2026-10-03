namespace MolBhav.Infrastructure.Billing;

public sealed class SubscriptionExpiryOptions
{
    public const string SectionName = "SubscriptionExpiry";

    public bool Enabled { get; set; } = true;

    /// <summary>How often lapsed subscriptions are swept. Also the worst-case delay before a lapsed Pro user is downgraded.</summary>
    public int IntervalMinutes { get; set; } = 15;

    /// <summary>Subscriptions expired per transaction; the worker keeps draining until a batch comes back short.</summary>
    public int BatchSize { get; set; } = 200;
}
