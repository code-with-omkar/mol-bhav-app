using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Ingestion.Admin.GetSourceFeedOptions;

internal sealed class GetSourceFeedOptionsQueryHandler(IPriceSourceRepository sources, ISourceFeedOptionsRepository feedOptions)
    : IQueryHandler<GetSourceFeedOptionsQuery, SourceFeedOptionsResponse>
{
    public async Task<Result<SourceFeedOptionsResponse>> Handle(GetSourceFeedOptionsQuery request, CancellationToken cancellationToken)
    {
        if (await sources.GetByIdAsync(request.PriceSourceId, cancellationToken) is null)
        {
            return Error.NotFound("PriceSource.NotFound", "Price source not found.");
        }

        // Empty (not an error) until a full pull has run: the app explains that and keeps the dropdowns disabled.
        return await feedOptions.GetByPriceSourceIdAsync(request.PriceSourceId, cancellationToken) is { } options
            ? new SourceFeedOptionsResponse(
                options.States,
                options.Commodities,
                [.. options.Markets.Select(m => new FeedMarketResponse(m.Name, m.State))],
                options.RefreshedAtUtc)
            : new SourceFeedOptionsResponse([], [], [], null);
    }
}
