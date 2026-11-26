using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Market.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.ImportFeedMarkets;

internal sealed class ImportFeedMarketsCommandHandler(
    IPriceSourceRepository sources,
    ISourceFeedOptionsRepository feedOptions,
    IStateRepository states,
    IMandiRepository mandis,
    IFeedMarketCodes marketCodes) : ICommandHandler<ImportFeedMarketsCommand, ImportFeedMarketsResponse>
{
    /// <summary>Only Agmarknet's market names are mapped onto mandi codes today.</summary>
    private const string SupportedSourceCode = "agmarknet";

    public async Task<Result<ImportFeedMarketsResponse>> Handle(ImportFeedMarketsCommand request, CancellationToken cancellationToken)
    {
        var source = await sources.GetByIdAsync(request.PriceSourceId, cancellationToken);
        if (source is null)
        {
            return Error.NotFound("PriceSource.NotFound", "Price source not found.");
        }

        if (!string.Equals(source.Code, SupportedSourceCode, StringComparison.OrdinalIgnoreCase))
        {
            return Error.Validation("FeedMarkets.SourceNotSupported", "Markets can only be added from the Agmarknet feed.");
        }

        var options = await feedOptions.GetByPriceSourceIdAsync(request.PriceSourceId, cancellationToken);
        var stateName = request.State!.Trim();
        var inState = options?.Markets.Where(m => string.Equals(m.State, stateName, StringComparison.OrdinalIgnoreCase)).ToList() ?? [];
        if (inState.Count == 0)
        {
            return Error.Validation(
                "FeedMarkets.NoFeedList",
                $"No markets are saved for '{stateName}'. Run a full pull so the feed's markets are recorded, then try again.");
        }

        var state = await states.GetByNameAsync(marketCodes.StateNameFor(stateName), cancellationToken);
        if (state is null)
        {
            return Error.Validation(
                "FeedMarkets.StateNotInCatalog",
                $"'{stateName}' is not in the catalog's list of states. Add it (or fix its spelling) under Market → States first.");
        }

        var (created, skipped) = await FeedMarketImporter.ImportAsync(
            state, request.Markets!, inState, mandis, marketCodes, new HashSet<string>(StringComparer.Ordinal), cancellationToken);

        return new ImportFeedMarketsResponse(created, skipped);
    }
}
