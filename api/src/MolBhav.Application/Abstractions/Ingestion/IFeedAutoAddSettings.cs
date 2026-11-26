namespace MolBhav.Application.Abstractions.Ingestion;

/// <summary>What a full pull may add to the catalog on its own, and where new commodities are filed.</summary>
public interface IFeedAutoAddSettings
{
    /// <summary>New feed markets become mandis (with their districts and states), visible at once.</summary>
    bool AddMarkets { get; }

    /// <summary>New feed commodities become products, hidden until an admin reviews them.</summary>
    bool AddCommodities { get; }

    /// <summary>Code of the sub-category new products are filed under.</summary>
    string CommoditySubCategoryCode { get; }

    /// <summary>Code of the unit new products are priced in.</summary>
    string CommodityUnitCode { get; }
}
