using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Pricing.GetLatestByLocation;

internal sealed class GetLatestByLocationQueryHandler(
    IPricingReadService readService,
    ILanguageContext languageContext,
    TimeProvider timeProvider)
    : IQueryHandler<GetLatestByLocationQuery, PagedResult<LocationLatestPriceResponse>>
{
    /// <summary>Older records are hidden so a stale price never reads as today's.</summary>
    public const int MaxAgeDays = 30;

    public async Task<Result<PagedResult<LocationLatestPriceResponse>>> Handle(GetLatestByLocationQuery request, CancellationToken cancellationToken)
    {
        var today = DateOnly.FromDateTime(timeProvider.GetUtcNow().UtcDateTime);

        return Result.Success(await readService.GetLatestByLocationAsync(
            new LatestByLocationFilter(
                request.LocationKind,
                request.LocationId,
                today.AddDays(-MaxAgeDays),
                CatalogLanguage.From(languageContext),
                new PageRequest(request.Page, request.PageSize)),
            cancellationToken));
    }
}
