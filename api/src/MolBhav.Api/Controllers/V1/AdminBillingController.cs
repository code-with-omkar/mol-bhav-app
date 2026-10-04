using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Billing;
using MolBhav.Api.Setup;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Billing.Admin.CreatePlan;
using MolBhav.Application.Features.Billing.Admin.ExpireSubscription;
using MolBhav.Application.Features.Billing.Admin.GetAdminPlans;
using MolBhav.Application.Features.Billing.Admin.GetAdminSubscriptions;
using MolBhav.Application.Features.Billing.Admin.GetAdminWebhook;
using MolBhav.Application.Features.Billing.Admin.GetAdminWebhooks;
using MolBhav.Application.Features.Billing.Admin.ReplayWebhook;
using MolBhav.Application.Features.Billing.Admin.UpdatePlan;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Billing;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Plan, subscription and payment-webhook administration (BRD §23/§25). Admin role only.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/billing")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminBillingController(ISender sender) : ApiControllerBase(sender)
{
    private const string PlansPath = "plans";
    private const string SubscriptionsPath = "subscriptions";
    private const string WebhooksPath = "webhooks";

    [HttpGet(PlansPath)]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminPlanResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPlans(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminPlansQuery(), cancellationToken));

    /// <response code="409">Code already used (<c>Plan.CodeAlreadyExists</c>).</response>
    [HttpPost(PlansPath)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreatePlan([FromBody] CreatePlanRequest request, CancellationToken cancellationToken)
    {
        var command = new CreatePlanCommand(request.Code, request.Name, request.Price, request.Currency, request.BillingPeriod);
        return CreatedEnvelope(await Sender.Send(command, cancellationToken), $"{Request.PathBase}/api/v1/admin/billing/{PlansPath}");
    }

    [HttpPut($"{PlansPath}/{{planId:guid}}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdatePlan(Guid planId, [FromBody] UpdatePlanRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new UpdatePlanCommand(planId, request.Name, request.Price, request.IsActive), cancellationToken));

    [HttpGet(SubscriptionsPath)]
    [ProducesResponseType<ApiResponse<PagedResult<AdminSubscriptionResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSubscriptions(
        [FromQuery] Guid? userId,
        [FromQuery] SubscriptionStatus? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize,
        CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetAdminSubscriptionsQuery(userId, status, page, pageSize), cancellationToken));

    [HttpPost($"{SubscriptionsPath}/{{subscriptionId:guid}}/expire")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> ExpireSubscription(Guid subscriptionId, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new ExpireSubscriptionCommand(subscriptionId), cancellationToken));

    /// <summary>Payment-gateway webhook inbox, newest first. <c>state=Parked</c> lists what needs review.</summary>
    [HttpGet(WebhooksPath)]
    [ProducesResponseType<ApiResponse<PagedResult<AdminWebhookResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetWebhooks(
        [FromQuery] WebhookInboxState? state,
        [FromQuery] string? eventType,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize,
        CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetAdminWebhooksQuery(state, eventType, page, pageSize), cancellationToken));

    /// <summary>One inbox row with its raw payload and last error.</summary>
    [HttpGet($"{WebhooksPath}/{{webhookId:guid}}")]
    [ProducesResponseType<ApiResponse<AdminWebhookDetailResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetWebhook(Guid webhookId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminWebhookQuery(webhookId), cancellationToken));

    /// <summary>Re-queues a parked webhook (fresh attempt budget); the processor applies it within seconds.</summary>
    /// <response code="409">Not parked (<c>Webhook.NotParked</c>).</response>
    [HttpPost($"{WebhooksPath}/{{webhookId:guid}}/replay")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> ReplayWebhook(Guid webhookId, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new ReplayWebhookCommand(webhookId), cancellationToken));
}
