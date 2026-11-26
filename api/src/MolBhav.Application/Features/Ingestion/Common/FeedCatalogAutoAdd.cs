using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Catalog.Admin.ImportFeedProducts;
using MolBhav.Application.Features.Market.Admin.ImportAllFeedMarkets;
using MolBhav.Domain.Catalog;

namespace MolBhav.Application.Features.Ingestion.Common;

/// <summary>Adds what a full pull saw for the first time to the catalog, so its prices are not skipped.</summary>
public interface IFeedCatalogAutoAdd
{
    /// <summary>Call after the pull's feed list has been recorded and before its prices are written.</summary>
    Task AddNewAsync(Guid priceSourceId, FeedNames names, CancellationToken cancellationToken);
}

/// <remarks>
/// It applies exactly the rules of the admin's "add from the feed" actions, which skip whatever the catalog already has.
/// What it adds is saved straight away (still inside the pull's transaction) so the same pull finds the new mandis.
/// New products start hidden, so their prices begin once an admin has filed and switched them on.
/// </remarks>
internal sealed partial class FeedCatalogAutoAdd(
    IFeedAutoAddSettings settings,
    IPriceSourceRepository sources,
    ISourceFeedOptionsRepository feedOptions,
    IStateRepository states,
    IMandiRepository mandis,
    IFeedMarketCodes feedCodes,
    IProductRepository products,
    IProcurementCategoryRepository categories,
    IUnitOfMeasureRepository units,
    IUnitOfWork unitOfWork,
    ILogger<FeedCatalogAutoAdd> logger) : IFeedCatalogAutoAdd
{
    /// <summary>The admin action takes at most this many commodities at a time.</summary>
    private const int CommodityBatch = 200;

    public async Task AddNewAsync(Guid priceSourceId, FeedNames names, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(names);
        if (!settings.AddMarkets && !settings.AddCommodities)
        {
            return;
        }

        // The importers read the saved feed list, which this pull has only just updated.
        await unitOfWork.SaveChangesAsync(cancellationToken);

        var marketsAdded = 0;
        if (settings.AddMarkets && names.Markets.Count > 0)
        {
            var result = await new ImportAllFeedMarketsCommandHandler(sources, feedOptions, states, mandis, feedCodes)
                .Handle(new ImportAllFeedMarketsCommand(priceSourceId), cancellationToken);
            marketsAdded = result.IsSuccess ? result.Value.MarketsCreated : 0;
        }

        var productsAdded = 0;
        if (settings.AddCommodities && names.Commodities.Count > 0)
        {
            productsAdded = await AddCommoditiesAsync(priceSourceId, names.Commodities, cancellationToken);
        }

        if (marketsAdded + productsAdded > 0)
        {
            await unitOfWork.SaveChangesAsync(cancellationToken);
            LogAdded(logger, marketsAdded, productsAdded);
        }
    }

    private async Task<int> AddCommoditiesAsync(Guid priceSourceId, IReadOnlyList<string> commodities, CancellationToken cancellationToken)
    {
        var subCategoryCode = CatalogCode.Create(settings.CommoditySubCategoryCode);
        var unitCode = CatalogCode.Create(settings.CommodityUnitCode);
        var subCategoryId = subCategoryCode.IsSuccess
            ? await categories.GetSubCategoryIdByCodeAsync(subCategoryCode.Value, cancellationToken)
            : null;
        var unitId = unitCode.IsSuccess ? await units.GetIdByCodeAsync(unitCode.Value, cancellationToken) : null;
        if (subCategoryId is null || unitId is null)
        {
            LogMissingDefaults(logger, settings.CommoditySubCategoryCode, settings.CommodityUnitCode);
            return 0;
        }

        var handler = new ImportFeedProductsCommandHandler(sources, feedOptions, products, categories, units, feedCodes);
        var added = 0;
        foreach (var batch in commodities.Chunk(CommodityBatch))
        {
            var result = await handler.Handle(
                new ImportFeedProductsCommand(priceSourceId, subCategoryId.Value, unitId.Value, batch, Hidden: true),
                cancellationToken);
            if (result.IsSuccess)
            {
                added += result.Value.Created;
            }

            // Saved per batch so the next one sees these codes as taken.
            await unitOfWork.SaveChangesAsync(cancellationToken);
        }

        return added;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Full pull added {Markets} new mandi(s) and {Products} new hidden product(s) to the catalog")]
    private static partial void LogAdded(ILogger logger, int markets, int products);

    [LoggerMessage(Level = LogLevel.Warning, Message = "New commodities were not added: sub-category '{SubCategory}' or unit '{Unit}' does not exist")]
    private static partial void LogMissingDefaults(ILogger logger, string subCategory, string unit);
}
