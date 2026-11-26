namespace MolBhav.Application.Abstractions.Ingestion;

/// <summary>
/// The catalog codes a source's market and commodity names resolve to during ingestion. Used when adding a feed market
/// or commodity to the catalog, so the new mandi or product gets exactly the code that incoming prices will be looked
/// up under.
/// </summary>
public interface IFeedMarketCodes
{
    /// <summary>
    /// The mandi code for <paramref name="marketName"/> in <paramref name="state"/> (empty when the name has no usable
    /// characters). The state matters because two states can have a market of the same name.
    /// </summary>
    string CodeFor(string marketName, string state);

    /// <summary>The product code for <paramref name="commodityName"/> (empty when the name has no usable characters).</summary>
    string ProductCodeFor(string commodityName);

    /// <summary>The catalog's name for a feed state (the same name unless the source spells it differently).</summary>
    string StateNameFor(string feedState);

    /// <summary>The catalog's name for a feed district of <paramref name="stateName"/> (a catalog state name).</summary>
    string DistrictNameFor(string stateName, string feedDistrict);
}
