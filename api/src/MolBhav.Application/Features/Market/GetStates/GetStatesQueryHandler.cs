using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Market.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Market.GetStates;

internal sealed class GetStatesQueryHandler(IMarketReadService readService) : IQueryHandler<GetStatesQuery, IReadOnlyList<StateResponse>>
{
    public async Task<Result<IReadOnlyList<StateResponse>>> Handle(GetStatesQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetStatesAsync(cancellationToken));
}
