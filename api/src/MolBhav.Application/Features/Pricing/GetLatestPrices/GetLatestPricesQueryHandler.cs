using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Pricing.GetLatestPrices;

internal sealed class GetLatestPricesQueryHandler(IPricingReadService readService, TimeProvider timeProvider)
    : IQueryHandler<GetLatestPricesQuery, PagedResult<LatestPriceResponse>>
{
    public async Task<Result<PagedResult<LatestPriceResponse>>> Handle(GetLatestPricesQuery request, CancellationToken cancellationToken)
    {
        DateOnly? since = request.MaxAgeDays is { } days
            ? DateOnly.FromDateTime(timeProvider.GetUtcNow().UtcDateTime).AddDays(-days)
            : null;
        return Result.Success(await readService.GetLatestPricesAsync(
            new LatestPriceFilter(
                request.ProductId, request.LocationKind, request.DistrictId, new PageRequest(request.Page, request.PageSize),
                request.StateId, request.LocationId, since, request.CheapestFirst),
            cancellationToken));
    }
}
