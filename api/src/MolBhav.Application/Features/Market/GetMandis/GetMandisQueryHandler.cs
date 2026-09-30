using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Market.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Market.GetMandis;

internal sealed class GetMandisQueryHandler(IMarketReadService readService) : IQueryHandler<GetMandisQuery, PagedResult<MandiResponse>>
{
    public async Task<Result<PagedResult<MandiResponse>>> Handle(GetMandisQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetMandisAsync(
            request.DistrictId,
            string.IsNullOrWhiteSpace(request.Search) ? null : request.Search.Trim(),
            new PageRequest(request.Page, request.PageSize),
            cancellationToken));
}
