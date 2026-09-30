using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Admin.GetAdminCoupons;

internal sealed class GetAdminCouponsQueryHandler(IBillingReadService readService)
    : IQueryHandler<GetAdminCouponsQuery, PagedResult<AdminCouponResponse>>
{
    public async Task<Result<PagedResult<AdminCouponResponse>>> Handle(GetAdminCouponsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminCouponsAsync(new PageRequest(request.Page, request.PageSize), cancellationToken));
}
