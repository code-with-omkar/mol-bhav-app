using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Promotions.Admin.GetAdvertisers;

internal sealed class GetAdvertisersQueryHandler(IPromotionReadService readService)
    : IQueryHandler<GetAdvertisersQuery, IReadOnlyList<AdvertiserResponse>>
{
    public async Task<Result<IReadOnlyList<AdvertiserResponse>>> Handle(GetAdvertisersQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdvertisersAsync(cancellationToken));
}
