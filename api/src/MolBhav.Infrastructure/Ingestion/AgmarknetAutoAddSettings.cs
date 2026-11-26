using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Ingestion;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>The "add what is new" settings, from the <c>Agmarknet</c> configuration section.</summary>
internal sealed class AgmarknetAutoAddSettings(IOptions<AgmarknetOptions> options) : IFeedAutoAddSettings
{
    public bool AddMarkets => options.Value.AutoAddMarkets;

    public bool AddCommodities => options.Value.AutoAddCommodities;

    public string CommoditySubCategoryCode => options.Value.AutoAddSubCategoryCode;

    public string CommodityUnitCode => options.Value.AutoAddUnitCode;
}
