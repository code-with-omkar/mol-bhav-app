using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Pricing.Admin.GetAdminPriceSources;

internal sealed class GetAdminPriceSourcesQueryHandler(IPricingReadService readService)
    : IQueryHandler<GetAdminPriceSourcesQuery, IReadOnlyList<AdminPriceSourceResponse>>
{
    public async Task<Result<IReadOnlyList<AdminPriceSourceResponse>>> Handle(GetAdminPriceSourcesQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminPriceSourcesAsync(cancellationToken));
}
