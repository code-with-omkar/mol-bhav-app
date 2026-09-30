using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Billing.Models;

namespace MolBhav.Application.Features.Billing.Admin.GetAdminCoupons;

public sealed record GetAdminCouponsQuery(int Page, int PageSize) : IQuery<PagedResult<AdminCouponResponse>>;
