using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Billing;
using MolBhav.Api.Setup;
using MolBhav.Application.Features.Billing.ActivateSubscription;
using MolBhav.Application.Features.Billing.CancelSubscription;
using MolBhav.Application.Features.Billing.GetMySubscription;
using MolBhav.Application.Features.Billing.GetPlans;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Application.Features.Billing.Subscribe;
using MolBhav.Application.Features.Billing.ValidateCoupon;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Plan catalog, checkout, and the signed-in user's subscription. Requires a signed-in user (fallback auth policy).</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/billing")]
public sealed class BillingController(ISender sender) : ApiControllerBase(sender)
{
    [HttpGet("plans")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<PlanResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPlans(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetPlansQuery(), cancellationToken));

    /// <summary>Checkout step 1: opens a gateway order for the plan and returns what the Razorpay SDK needs.</summary>
    /// <response code="400">Invalid request or coupon (<c>Coupon.Invalid</c>).</response>
    /// <response code="404">Unknown or inactive plan (<c>Plan.NotFound</c>).</response>
    /// <response code="409">Already subscribed and not within the renewal window (<c>Subscription.AlreadyActive</c>).</response>
    /// <response code="502">The payment gateway did not create the order (<c>Payment.GatewayUnavailable</c>).</response>
    [HttpPost("subscribe")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<SubscribeResponseDto>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status502BadGateway, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Subscribe([FromBody] SubscribeRequest request, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new SubscribeCommand(request.PlanCode ?? string.Empty, request.CouponCode), cancellationToken));

    /// <summary>Checkout step 2: verifies the checkout signature and activates. Idempotent.</summary>
    /// <response code="400">Signature mismatch (<c>Payment.InvalidSignature</c>).</response>
    /// <response code="404">No such order for this user (<c>Subscription.NotFound</c>).</response>
    [HttpPost("subscription/activate")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<SubscriptionResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> ActivateSubscription([FromBody] ActivateSubscriptionRequest request, CancellationToken cancellationToken)
    {
        var command = new ActivateSubscriptionCommand(
            request.RazorpayOrderId ?? string.Empty,
            request.RazorpayPaymentId ?? string.Empty,
            request.RazorpaySignature ?? string.Empty);
        return OkEnvelope(await Sender.Send(command, cancellationToken));
    }

    [HttpGet("subscription")]
    [ProducesResponseType<ApiResponse<SubscriptionResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetMySubscription(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetMySubscriptionQuery(), cancellationToken));

    [HttpPost("subscription/cancel")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CancelSubscription(CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new CancelSubscriptionCommand(), cancellationToken));

    /// <summary>Prices a coupon against a plan without consuming it. An unusable coupon is a 200 with <c>isValid: false</c>.</summary>
    [HttpPost("coupons/validate")]
    [EnableRateLimiting(RateLimitPolicies.CouponValidate)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CouponValidationDto>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> ValidateCoupon([FromBody] ValidateCouponRequest request, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new ValidateCouponQuery(request.Code ?? string.Empty, request.PlanCode ?? string.Empty), cancellationToken));
}
