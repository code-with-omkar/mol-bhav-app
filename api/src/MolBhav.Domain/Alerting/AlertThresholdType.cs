namespace MolBhav.Domain.Alerting;

/// <summary>
/// What an <see cref="AlertRule"/> watches for (BRD §15). <see cref="PriceDrop"/>/<see cref="PriceSpike"/> compare
/// the percent move against the previous price at the same location; <see cref="PriceBelow"/>/<see cref="PriceAbove"/>
/// watch an absolute rupee level and fire only on the crossing, not on every price that stays past it.
/// </summary>
public enum AlertThresholdType
{
    PriceDrop = 0,
    PriceSpike = 1,
    PriceBelow = 2,
    PriceAbove = 3,
}
