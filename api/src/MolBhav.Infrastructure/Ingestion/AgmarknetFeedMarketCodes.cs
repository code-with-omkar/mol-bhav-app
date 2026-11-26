using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Ingestion;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>Resolves an Agmarknet market or commodity name to a catalog code with the same rule the ingestion uses (slug + configured map).</summary>
internal sealed class AgmarknetFeedMarketCodes(IOptionsMonitor<AgmarknetOptions> options) : IFeedMarketCodes
{
    public string CodeFor(string marketName, string state) => AgmarknetRowMapper.ToMarketCode(marketName, options.CurrentValue, state);

    public string ProductCodeFor(string commodityName) => AgmarknetRowMapper.ToProductCode(commodityName, options.CurrentValue);

    public string StateNameFor(string feedState)
    {
        var name = feedState.Trim();
        return options.CurrentValue.StateNameMap.TryGetValue(name, out var mapped) ? mapped : name;
    }

    public string DistrictNameFor(string stateName, string feedDistrict)
    {
        var name = feedDistrict.Trim();
        return options.CurrentValue.DistrictNameMap.TryGetValue($"{stateName}/{name}", out var mapped) ? mapped : name;
    }
}
