using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Pricing.GetPriceHistory;

internal sealed class GetPriceHistoryQueryHandler(IPricingReadService readService)
    : IQueryHandler<GetPriceHistoryQuery, IReadOnlyList<PriceHistoryPointResponse>>
{
    public async Task<Result<IReadOnlyList<PriceHistoryPointResponse>>> Handle(GetPriceHistoryQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetPriceHistoryAsync(
            new PriceHistoryFilter(request.ProductId, request.LocationKind, request.LocationId, request.FromDate, request.ToDate),
            cancellationToken));
}
