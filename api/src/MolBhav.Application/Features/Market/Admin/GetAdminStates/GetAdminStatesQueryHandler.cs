using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Market.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Market.Admin.GetAdminStates;

internal sealed class GetAdminStatesQueryHandler(IMarketReadService readService)
    : IQueryHandler<GetAdminStatesQuery, IReadOnlyList<AdminStateResponse>>
{
    public async Task<Result<IReadOnlyList<AdminStateResponse>>> Handle(GetAdminStatesQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminStatesAsync(cancellationToken));
}
