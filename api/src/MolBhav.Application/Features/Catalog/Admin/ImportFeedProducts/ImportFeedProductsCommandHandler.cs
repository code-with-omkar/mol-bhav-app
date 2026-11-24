using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Catalog.Admin.ImportFeedProducts;

internal sealed class ImportFeedProductsCommandHandler(
    IPriceSourceRepository sources,
    ISourceFeedOptionsRepository feedOptions,
    IProductRepository products,
    IProcurementCategoryRepository categories,
    IUnitOfMeasureRepository units,
    IFeedMarketCodes feedCodes) : ICommandHandler<ImportFeedProductsCommand, ImportFeedProductsResponse>
{
    /// <summary>Only Agmarknet's commodity names are mapped onto product codes today.</summary>
    private const string SupportedSourceCode = "agmarknet";

    public async Task<Result<ImportFeedProductsResponse>> Handle(ImportFeedProductsCommand request, CancellationToken cancellationToken)
    {
        var source = await sources.GetByIdAsync(request.PriceSourceId, cancellationToken);
        if (source is null)
        {
            return Error.NotFound("PriceSource.NotFound", "Price source not found.");
        }

        if (!string.Equals(source.Code, SupportedSourceCode, StringComparison.OrdinalIgnoreCase))
        {
            return Error.Validation("FeedProducts.SourceNotSupported", "Commodities can only be added from the Agmarknet feed.");
        }

        var options = await feedOptions.GetByPriceSourceIdAsync(request.PriceSourceId, cancellationToken);
        if (options is null || options.Commodities.Count == 0)
        {
            return Error.Validation(
                "FeedProducts.NoFeedList",
                "No commodities are saved for this source. Run a full pull so the feed's commodities are recorded, then try again.");
        }

        var references = await ProductReferences.CheckAsync(categories, units, request.SubCategoryId, request.DefaultUnitId, cancellationToken);
        if (references.IsFailure)
        {
            return Result.Failure<ImportFeedProductsResponse>(references.Error);
        }

        var created = 0;
        var skipped = new List<SkippedFeedCommodity>();
        var codesAdded = new HashSet<string>(StringComparer.Ordinal);

        foreach (var name in request.Commodities!.Select(n => n.Trim()).Where(n => n.Length > 0).Distinct(StringComparer.OrdinalIgnoreCase))
        {
            var feedName = options.Commodities.FirstOrDefault(c => string.Equals(c, name, StringComparison.OrdinalIgnoreCase));
            if (feedName is null)
            {
                skipped.Add(new SkippedFeedCommodity(name, FeedCommoditySkipReason.NotInFeed));
                continue;
            }

            var code = CatalogCode.Create(feedCodes.ProductCodeFor(feedName));
            if (code.IsFailure)
            {
                skipped.Add(new SkippedFeedCommodity(feedName, FeedCommoditySkipReason.CodeInvalid));
                continue;
            }

            // Two feed names can resolve to one code (spelling variants); the first one wins.
            if (codesAdded.Contains(code.Value.Value) || await products.CodeExistsAsync(code.Value, cancellationToken))
            {
                skipped.Add(new SkippedFeedCommodity(feedName, FeedCommoditySkipReason.AlreadyInCatalog));
                continue;
            }

            var english = CatalogTranslation.Create(LanguageCode.English, feedName);
            if (english.IsFailure)
            {
                skipped.Add(new SkippedFeedCommodity(feedName, FeedCommoditySkipReason.NameInvalid));
                continue;
            }

            var product = Product.Create(code.Value, request.SubCategoryId, request.DefaultUnitId, 0, null, [english.Value]);
            if (product.IsFailure)
            {
                skipped.Add(new SkippedFeedCommodity(feedName, FeedCommoditySkipReason.NameInvalid));
                continue;
            }

            products.Add(product.Value);
            codesAdded.Add(code.Value.Value);
            created++;
        }

        return new ImportFeedProductsResponse(created, skipped);
    }
}
