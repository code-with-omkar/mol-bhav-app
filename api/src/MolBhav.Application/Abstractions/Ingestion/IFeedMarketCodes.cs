namespace MolBhav.Application.Abstractions.Ingestion;

/// <summary>
/// The catalog codes a source's market and commodity names resolve to during ingestion. Used when adding a feed market
/// or commodity to the catalog, so the new mandi or product gets exactly the code that incoming prices will be looked
/// up under.
/// </summary>
public interface IFeedMarketCodes
{
    /// <summary>The mandi code for <paramref name="marketName"/> (empty when the name has no usable characters).</summary>
    string CodeFor(string marketName);

    /// <summary>The product code for <paramref name="commodityName"/> (empty when the name has no usable characters).</summary>
    string ProductCodeFor(string commodityName);
}
