using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Domain.Alerting;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Alerting.Opportunities.ScanMarketOpportunities;

/// <summary>
/// For each watchlist item: the home price is the cheapest fresh price in the user's profile district; every market
/// outside it is priced as landed (price + cost components) and the biggest saving wins if it clears
/// <see cref="IOpportunitySettings.MinSavingsPercent"/>. Both sides always compare the same variant — a watch without
/// a variant is checked per variant and the best one kept. Runs inside <c>UnitOfWorkBehavior</c>, so all new
/// opportunities and their notification events commit together.
/// </summary>
internal sealed partial class ScanMarketOpportunitiesCommandHandler(
    IMarketOpportunityReadService readService,
    IMarketOpportunityRepository opportunities,
    ICostComponentRepository costComponents,
    IOpportunitySettings settings,
    TimeProvider timeProvider,
    ILogger<ScanMarketOpportunitiesCommandHandler> logger)
    : ICommandHandler<ScanMarketOpportunitiesCommand, OpportunityScanResult>
{
    public async Task<Result<OpportunityScanResult>> Handle(
        ScanMarketOpportunitiesCommand request,
        CancellationToken cancellationToken)
    {
        var nowUtc = timeProvider.GetUtcNow();
        var today = IngestionDates.TodayIst(nowUtc);

        var watchers = await readService.GetWatchersAsync(cancellationToken);
        if (watchers.Count == 0)
        {
            return new OpportunityScanResult(0, 0, 0, today);
        }

        var productIds = watchers.Select(w => w.ProductId).Distinct().ToArray();
        var prices = await readService.GetLatestPricesAsync(
            productIds, today.AddDays(-Math.Max(1, settings.FreshnessDays)), cancellationToken);
        var pricesByProduct = prices.ToLookup(p => p.ProductId);

        var components = await costComponents.GetActiveAsync(cancellationToken);
        var alreadyFound = await opportunities.GetFoundOnAsync(today, cancellationToken);
        var foundNow = new HashSet<(Guid, Guid)>();

        var compared = 0;
        foreach (var watcher in watchers)
        {
            var key = (watcher.UserId, watcher.ProductId);
            if (alreadyFound.Contains(key) || foundNow.Contains(key))
            {
                continue;
            }

            var candidate = FindBest(watcher, pricesByProduct[watcher.ProductId], components);
            if (candidate is null)
            {
                continue;
            }

            compared++;
            var (variantId, home, best, landed) = candidate.Value;
            if (LandedCost.SavingsPercent(home.ModalPrice, landed) < settings.MinSavingsPercent)
            {
                continue;
            }

            var opportunity = MarketOpportunity.Create(
                watcher.UserId,
                watcher.ProductId,
                variantId,
                today,
                Location(home),
                home.ModalPrice,
                Location(best),
                best.ModalPrice,
                landed,
                best.RecordDate,
                nowUtc);

            if (opportunity.IsFailure)
            {
                LogRejected(logger, watcher.UserId, watcher.ProductId, opportunity.Error.Code);
                continue;
            }

            opportunities.Add(opportunity.Value);
            foundNow.Add(key);
        }

        LogScanned(logger, watchers.Count, compared, foundNow.Count, today);
        return new OpportunityScanResult(watchers.Count, compared, foundNow.Count, today);
    }

    /// <summary>The largest saving for one watch across its variants, or null when there is nothing to compare
    /// (no fresh home-district price, or no market outside the district).</summary>
    private (Guid? VariantId, OpportunityPrice Home, OpportunityPrice Best, decimal Landed)? FindBest(
        OpportunityWatcher watcher,
        IEnumerable<OpportunityPrice> productPrices,
        IReadOnlyList<Domain.Procurement.CostComponent> components)
    {
        var relevant = watcher.VariantId is { } variant
            ? productPrices.Where(p => p.VariantId == variant)
            : productPrices;

        (Guid? VariantId, OpportunityPrice Home, OpportunityPrice Best, decimal Landed)? best = null;
        decimal bestSaving = decimal.MinValue;

        foreach (var group in relevant.GroupBy(p => p.VariantId))
        {
            var home = group
                .Where(p => p.DistrictId == watcher.HomeDistrictId)
                .OrderBy(p => p.ModalPrice)
                .FirstOrDefault();
            if (home is null)
            {
                continue;
            }

            foreach (var other in group.Where(p => p.DistrictId != watcher.HomeDistrictId))
            {
                var landed = LandedCost.PerUnit(other.ModalPrice, components, settings.ReferenceQuantity);
                var saving = home.ModalPrice - landed;
                if (saving > bestSaving)
                {
                    bestSaving = saving;
                    best = (group.Key, home, other, landed);
                }
            }
        }

        return best;
    }

    private static MarketLocation Location(OpportunityPrice price) => price.LocationKind == LocationKind.Mandi
        ? MarketLocation.Mandi(price.MandiId!.Value)
        : MarketLocation.Supplier(price.SupplierId!.Value);

    [LoggerMessage(Level = LogLevel.Information, Message = "Opportunity scan for {DetectedOn}: {Watched} watched items, {Compared} compared, {Found} new opportunities")]
    private static partial void LogScanned(ILogger logger, int watched, int compared, int found, DateOnly detectedOn);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Opportunity for user {UserId}, product {ProductId} rejected: {ErrorCode}")]
    private static partial void LogRejected(ILogger logger, Guid userId, Guid productId, string errorCode);
}
