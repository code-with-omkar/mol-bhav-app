namespace MolBhav.Application.Abstractions.Ingestion;

/// <summary>
/// The catalog mandi code a source's market name resolves to during ingestion. Used when adding a feed market to the
/// catalog, so the new mandi gets exactly the code that incoming prices will be looked up under.
/// </summary>
public interface IFeedMarketCodes
{
    /// <summary>The code for <paramref name="marketName"/> (empty when the name has no usable characters).</summary>
    string CodeFor(string marketName);
}
