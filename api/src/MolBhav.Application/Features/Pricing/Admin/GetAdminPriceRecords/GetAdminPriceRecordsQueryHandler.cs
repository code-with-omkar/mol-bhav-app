using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Pricing.Admin.GetAdminPriceRecords;

internal sealed class GetAdminPriceRecordsQueryHandler(IPricingReadService readService)
    : IQueryHandler<GetAdminPriceRecordsQuery, PagedResult<AdminPriceRecordResponse>>
{
    public async Task<Result<PagedResult<AdminPriceRecordResponse>>> Handle(GetAdminPriceRecordsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminPriceRecordsAsync(
            new AdminPriceRecordFilter(
                request.ProductId, request.LocationKind, request.LocationId,
                request.FromDate, request.ToDate, request.IsVoided,
                new PageRequest(request.Page, request.PageSize)),
            cancellationToken));
}
