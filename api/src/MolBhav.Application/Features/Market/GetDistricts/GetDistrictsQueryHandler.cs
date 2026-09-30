using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Market.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Market.GetDistricts;

internal sealed class GetDistrictsQueryHandler(IMarketReadService readService) : IQueryHandler<GetDistrictsQuery, IReadOnlyList<DistrictResponse>>
{
    public async Task<Result<IReadOnlyList<DistrictResponse>>> Handle(GetDistrictsQuery request, CancellationToken cancellationToken)
    {
        var districts = await readService.GetDistrictsAsync(request.StateId, cancellationToken);
        return districts is null
            ? Error.NotFound("State.NotFound", "State not found.")
            : Result.Success(districts);
    }
}
