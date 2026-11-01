using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Alerting.Opportunities.GetOpportunities;
using MolBhav.Application.Features.Alerting.Opportunities.GetOpportunity;
using MolBhav.Application.Features.Alerting.Opportunities.MarkOpportunityRead;
using MolBhav.Application.Features.Alerting.Opportunities.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Cheaper markets for the signed-in user's watchlist products, found by the daily scan (BRD §13/§15).
/// Requires a signed-in user (fallback auth policy).</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/opportunities")]
public sealed class OpportunitiesController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>The user's opportunities, newest first.</summary>
    [HttpGet]
    [ProducesResponseType<ApiResponse<PagedResult<MarketOpportunityResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetOpportunities(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize,
        CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetOpportunitiesQuery(page, pageSize), cancellationToken));

    /// <summary>One opportunity with every market's current price and landed price for the same product/variant.</summary>
    /// <response code="404">Unknown opportunity, or another user's.</response>
    [HttpGet("{opportunityId:guid}")]
    [ProducesResponseType<ApiResponse<MarketOpportunityDetailResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetOpportunity(Guid opportunityId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetOpportunityQuery(opportunityId), cancellationToken));

    [HttpPost("{opportunityId:guid}/read")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> MarkRead(Guid opportunityId, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new MarkOpportunityReadCommand(opportunityId), cancellationToken));
}
