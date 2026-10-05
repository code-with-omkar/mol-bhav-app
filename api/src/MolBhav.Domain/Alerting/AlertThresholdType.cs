namespace MolBhav.Domain.Alerting;

/// <summary>
/// What an <see cref="AlertRule"/> watches for (BRD §15). <see cref="PriceDrop"/>/<see cref="PriceSpike"/>/
/// <see cref="PriceChange"/> compare the percent move against the previous price at the same location;
/// <see cref="PriceBelow"/>/<see cref="PriceAbove"/> watch an absolute rupee level and fire only on the crossing, not on
/// every price that stays past it. Stored as text — append new members, never renumber.
/// </summary>
public enum AlertThresholdType
{
    PriceDrop = 0,
    PriceSpike = 1,
    PriceBelow = 2,
    PriceAbove = 3,

    /// <summary>A move of at least the threshold percent in either direction — the app's "changes by %" condition.</summary>
    PriceChange = 4,
}
