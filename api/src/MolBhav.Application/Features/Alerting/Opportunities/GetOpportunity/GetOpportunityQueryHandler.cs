using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Application.Features.Alerting.Opportunities.Models;
using MolBhav.Application.Features.Catalog;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Alerting.Opportunities.GetOpportunity;

internal sealed class GetOpportunityQueryHandler(
    IMarketOpportunityReadService readService,
    ICostComponentRepository costComponents,
    IOpportunitySettings settings,
    ICurrentUser currentUser,
    ILanguageContext languageContext,
    TimeProvider timeProvider)
    : IQueryHandler<GetOpportunityQuery, MarketOpportunityDetailResponse>
{
    public async Task<Result<MarketOpportunityDetailResponse>> Handle(
        GetOpportunityQuery request,
        CancellationToken cancellationToken)
    {
        var opportunity = await readService.GetOpportunityAsync(
            currentUser.GetRequiredUserId(),
            request.OpportunityId,
            CatalogLanguage.From(languageContext),
            cancellationToken);
        if (opportunity is null)
        {
            return Error.NotFound("MarketOpportunity.NotFound", "Opportunity not found.");
        }

        var since = IngestionDates.TodayIst(timeProvider.GetUtcNow()).AddDays(-Math.Max(1, settings.FreshnessDays));
        var rows = await readService.GetMarketPricesAsync(
            opportunity.Product.Id, opportunity.VariantId, since, cancellationToken);
        var components = await costComponents.GetActiveAsync(cancellationToken);

        // The home district is the district of the opportunity's home market.
        var homeDistrictId = rows.FirstOrDefault(r => r.LocationId == opportunity.Home.LocationId)?.DistrictId;

        var markets = rows
            .Select(r =>
            {
                var isHome = homeDistrictId is { } home && r.DistrictId == home;
                return new OpportunityMarketPriceResponse(
                    r.LocationKind,
                    r.LocationId,
                    r.Name,
                    r.DistrictName,
                    r.ModalPrice,
                    isHome ? r.ModalPrice : LandedCost.PerUnit(r.ModalPrice, components, settings.ReferenceQuantity),
                    isHome,
                    r.RecordDate);
            })
            .OrderBy(m => m.LandedPrice)
            .ToArray();

        return new MarketOpportunityDetailResponse(opportunity, markets, settings.ReferenceQuantity);
    }
}
