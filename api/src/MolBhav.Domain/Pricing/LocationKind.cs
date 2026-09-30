namespace MolBhav.Domain.Pricing;

/// <summary>Which market-module aggregate a <see cref="PriceRecord"/>'s location points to. Exactly one of Mandi/Supplier id is set to match.</summary>
public enum LocationKind
{
    /// <summary>Agriculture (BRD §11): an APMC mandi.</summary>
    Mandi = 0,

    /// <summary>Construction (BRD §12): a regional supplier/hub.</summary>
    Supplier = 1,
}
