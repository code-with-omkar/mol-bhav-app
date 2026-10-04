using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Promotions;
using MolBhav.Api.Setup;
using MolBhav.Application.Features.Promotions.GetPromotion;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Application.Features.Promotions.RecordPromotionEvents;
using MolBhav.Domain.Promotions;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// Direct-sold sponsored cards for the signed-in user (fallback auth policy). An empty slot means the app shows an
/// AdMob native ad instead; Pro users always get an empty slot.
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/promotions")]
public sealed class PromotionsController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>The sponsored card for one slot, or <c>promotion: null</c> when nothing is booked for this user.</summary>
    [HttpGet]
    [ProducesResponseType<ApiResponse<PromotionSlotResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetPromotion([FromQuery] PromotionPlacement? placement, CancellationToken cancellationToken)
    {
        // Personalised per user and capped per day: never let a shared cache hand one user's card to another.
        Response.Headers.CacheControl = "private, no-store";
        return OkEnvelope(await Sender.Send(new GetPromotionQuery(placement), cancellationToken));
    }

    /// <summary>Batched impressions and clicks. Unknown campaigns are ignored; counts are capped per campaign per call.</summary>
    [HttpPost("events")]
    [EnableRateLimiting(RateLimitPolicies.PromotionEvents)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status429TooManyRequests, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> RecordEvents([FromBody] RecordPromotionEventsRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new RecordPromotionEventsCommand(request.ToInputs()), cancellationToken));
}
