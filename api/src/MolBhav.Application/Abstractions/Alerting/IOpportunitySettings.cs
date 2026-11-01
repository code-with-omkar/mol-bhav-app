namespace MolBhav.Application.Abstractions.Alerting;

/// <summary>Market-opportunity tuning, bound from the <c>Opportunities</c> configuration section.</summary>
public interface IOpportunitySettings
{
    /// <summary>Minimum saving after costs, in percent of the home price (e.g. 10).</summary>
    decimal MinSavingsPercent { get; }

    /// <summary>Prices older than this many days are ignored on both sides.</summary>
    int FreshnessDays { get; }

    /// <summary>Order size (in the product's default unit) that fixed-amount cost components are spread over to get a
    /// per-unit landed price.</summary>
    decimal ReferenceQuantity { get; }
}
