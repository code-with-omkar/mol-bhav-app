using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Billing;
using MolBhav.Api.Setup;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Billing.Admin.CreateCoupon;
using MolBhav.Application.Features.Billing.Admin.GetAdminCoupons;
using MolBhav.Application.Features.Billing.Admin.UpdateCoupon;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Billing;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Coupon administration. Admin role only.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/coupons")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminCouponsController(ISender sender) : ApiControllerBase(sender)
{
    [HttpGet]
    [ProducesResponseType<ApiResponse<PagedResult<AdminCouponResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize,
        CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetAdminCouponsQuery(page, pageSize), cancellationToken));

    /// <response code="409">Code already used (<c>Coupon.Duplicate</c>).</response>
    [HttpPost]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Create([FromBody] CreateCouponRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateCouponCommand(
            request.Code ?? string.Empty,
            request.DiscountType ?? DiscountType.Fixed,
            request.DiscountValue ?? 0,
            request.MaxUses,
            request.ValidFrom ?? DateTimeOffset.UtcNow,
            request.ValidTo,
            request.ApplicablePlanCode,
            request.MinAmountPaise);
        return CreatedEnvelope(await Sender.Send(command, cancellationToken), $"{Request.PathBase}/api/v1/admin/coupons");
    }

    /// <response code="400">Invalid validity, or max uses below uses already made (<c>Coupon.MaxUsesBelowUsage</c>).</response>
    [HttpPut("{id:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateCouponRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new UpdateCouponCommand(id, request.IsActive, request.ValidTo, request.MaxUses), cancellationToken));
}
