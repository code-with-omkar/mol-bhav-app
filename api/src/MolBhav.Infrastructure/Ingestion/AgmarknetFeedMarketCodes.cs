using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Ingestion;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>Resolves an Agmarknet market name to a mandi code with the same rule the ingestion uses (slug + configured map).</summary>
internal sealed class AgmarknetFeedMarketCodes(IOptionsMonitor<AgmarknetOptions> options) : IFeedMarketCodes
{
    public string CodeFor(string marketName) => AgmarknetRowMapper.ToMarketCode(marketName, options.CurrentValue);
}
