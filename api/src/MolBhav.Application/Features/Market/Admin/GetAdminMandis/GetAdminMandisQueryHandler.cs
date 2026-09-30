using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Market.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Market.Admin.GetAdminMandis;

internal sealed class GetAdminMandisQueryHandler(IMarketReadService readService)
    : IQueryHandler<GetAdminMandisQuery, PagedResult<AdminMandiResponse>>
{
    public async Task<Result<PagedResult<AdminMandiResponse>>> Handle(GetAdminMandisQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminMandisAsync(
            request.DistrictId,
            string.IsNullOrWhiteSpace(request.Search) ? null : request.Search.Trim(),
            request.IsActive,
            new PageRequest(request.Page, request.PageSize),
            cancellationToken));
}
