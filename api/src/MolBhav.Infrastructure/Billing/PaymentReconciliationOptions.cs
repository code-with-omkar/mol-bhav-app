namespace MolBhav.Infrastructure.Billing;

public sealed class PaymentReconciliationOptions
{
    public const string SectionName = "PaymentReconciliation";

    public bool Enabled { get; set; } = true;

    /// <summary>How often pending orders are checked against the gateway. Also the worst-case delay before a payment
    /// whose webhook was lost activates the subscription.</summary>
    public int IntervalMinutes { get; set; } = 15;

    /// <summary>
    /// Orders younger than this are left to the webhook, which normally lands within seconds; checking earlier would
    /// only duplicate its work.
    /// </summary>
    public int MinAgeMinutes { get; set; } = 10;

    /// <summary>
    /// Orders older than this are no longer checked. Checkout completes within minutes of the order, so a still-unpaid
    /// order this old is an abandoned checkout; the cap bounds gateway calls per abandoned order
    /// (≈ MaxAgeHours × 60 / IntervalMinutes).
    /// </summary>
    public int MaxAgeHours { get; set; } = 24;

    /// <summary>Orders checked per sweep (one gateway call each), newest first.</summary>
    public int BatchSize { get; set; } = 100;
}
