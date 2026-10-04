using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Promotions;
using MolBhav.Api.Setup;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Promotions.Admin.CreateAdvertiser;
using MolBhav.Application.Features.Promotions.Admin.CreateCampaign;
using MolBhav.Application.Features.Promotions.Admin.GetAdminCampaigns;
using MolBhav.Application.Features.Promotions.Admin.GetAdvertisers;
using MolBhav.Application.Features.Promotions.Admin.GetCampaignStats;
using MolBhav.Application.Features.Promotions.Admin.SetCampaignStatus;
using MolBhav.Application.Features.Promotions.Admin.UpdateAdvertiser;
using MolBhav.Application.Features.Promotions.Admin.UpdateCampaign;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Promotions;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Sells and runs sponsored placements: advertisers, their campaigns, and delivery numbers. Admin role only.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/promotions")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminPromotionsController(ISender sender) : ApiControllerBase(sender)
{
    [HttpGet("advertisers")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdvertiserResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAdvertisers(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdvertisersQuery(), cancellationToken));

    [HttpPost("advertisers")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateAdvertiser([FromBody] AdvertiserRequest request, CancellationToken cancellationToken) =>
        CreatedEnvelope(
            await Sender.Send(
                new CreateAdvertiserCommand(request.Name, request.ContactName, request.ContactPhone, request.Gstin),
                cancellationToken),
            $"{Request.PathBase}/api/v1/admin/promotions/advertisers");

    [HttpPut("advertisers/{advertiserId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateAdvertiser(Guid advertiserId, [FromBody] AdvertiserRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(
            new UpdateAdvertiserCommand(advertiserId, request.Name, request.ContactName, request.ContactPhone, request.Gstin),
            cancellationToken));

    /// <summary>Newest first, with today's (IST) and lifetime delivery.</summary>
    [HttpGet("campaigns")]
    [ProducesResponseType<ApiResponse<PagedResult<AdminCampaignResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCampaigns(
        [FromQuery] CampaignStatus? status,
        [FromQuery] Guid? advertiserId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize,
        CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetAdminCampaignsQuery(status, advertiserId, page, pageSize), cancellationToken));

    /// <summary>Created as <c>Draft</c>; activate it to start serving.</summary>
    /// <response code="400">Invalid creative, schedule or targets, or an unknown category/state.</response>
    /// <response code="404">Unknown advertiser.</response>
    [HttpPost("campaigns")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateCampaign([FromBody] CreateCampaignRequest request, CancellationToken cancellationToken) =>
        CreatedEnvelope(
            await Sender.Send(
                new CreateCampaignCommand(request.AdvertiserId ?? Guid.Empty, request.Campaign?.ToInput()),
                cancellationToken),
            $"{Request.PathBase}/api/v1/admin/promotions/campaigns");

    /// <response code="400">Invalid input, or the campaign has ended (<c>Campaign.Ended</c>).</response>
    [HttpPut("campaigns/{campaignId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateCampaign(Guid campaignId, [FromBody] CampaignRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new UpdateCampaignCommand(campaignId, request.ToInput()), cancellationToken));

    /// <summary><c>Activate</c>, <c>Pause</c> or <c>End</c> (terminal).</summary>
    [HttpPut("campaigns/{campaignId:guid}/status")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> SetStatus(Guid campaignId, [FromBody] SetCampaignStatusRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new SetCampaignStatusCommand(campaignId, request.Action), cancellationToken));

    /// <summary>Daily delivery (IST days, inclusive). Defaults to the last 30 days; at most 366.</summary>
    [HttpGet("campaigns/{campaignId:guid}/stats")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<CampaignDailyStatResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetStats(
        Guid campaignId,
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to,
        CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetCampaignStatsQuery(campaignId, from, to), cancellationToken));
}
