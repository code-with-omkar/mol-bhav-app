using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Ingestion;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>Resolves an Agmarknet market or commodity name to a catalog code with the same rule the ingestion uses (slug + configured map).</summary>
internal sealed class AgmarknetFeedMarketCodes(IOptionsMonitor<AgmarknetOptions> options) : IFeedMarketCodes
{
    public string CodeFor(string marketName) => AgmarknetRowMapper.ToMarketCode(marketName, options.CurrentValue);

    public string ProductCodeFor(string commodityName) => AgmarknetRowMapper.ToProductCode(commodityName, options.CurrentValue);
}
