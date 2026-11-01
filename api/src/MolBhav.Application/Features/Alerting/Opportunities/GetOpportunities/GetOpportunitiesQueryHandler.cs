using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Alerting.Opportunities.Models;
using MolBhav.Application.Features.Catalog;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Alerting.Opportunities.GetOpportunities;

internal sealed class GetOpportunitiesQueryHandler(
    IMarketOpportunityReadService readService,
    ICurrentUser currentUser,
    ILanguageContext languageContext)
    : IQueryHandler<GetOpportunitiesQuery, PagedResult<MarketOpportunityResponse>>
{
    public async Task<Result<PagedResult<MarketOpportunityResponse>>> Handle(
        GetOpportunitiesQuery request,
        CancellationToken cancellationToken) =>
        Result.Success(await readService.GetOpportunitiesAsync(
            currentUser.GetRequiredUserId(),
            CatalogLanguage.From(languageContext),
            new PageRequest(request.Page, request.PageSize),
            cancellationToken));
}
