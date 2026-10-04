using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Monetization;
using MolBhav.Application.Features.Monetization.CompleteAdUnlockWithoutAds;
using MolBhav.Application.Features.Monetization.GetAdUnlockSession;
using MolBhav.Application.Features.Monetization.GetEntitlements;
using MolBhav.Application.Features.Monetization.Models;
using MolBhav.Application.Features.Monetization.StartAdUnlock;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// Free-tier limits and rewarded-ad unlocks for the signed-in user (fallback auth policy). The limits themselves are
/// enforced where items are created (watchlist, alert rules, reports); these endpoints only describe and extend them.
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/monetization")]
public sealed class MonetizationController(ISender sender) : ApiControllerBase(sender)
{
    [HttpGet("entitlements")]
    [ProducesResponseType<ApiResponse<EntitlementsResponse>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetEntitlements(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetEntitlementsQuery(), cancellationToken));

    /// <summary>Starts a "watch N ads" unlock; its id goes into the rewarded ad's SSV custom data.</summary>
    /// <response code="403">Nothing left to unlock today or ever (<c>AdUnlock.LimitReached</c>).</response>
    /// <response code="409">Pro users have no limits (<c>AdUnlock.NotNeeded</c>).</response>
    [HttpPost("unlock-sessions")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<AdUnlockSessionResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> StartAdUnlock([FromBody] StartAdUnlockRequest request, CancellationToken cancellationToken)
    {
        var result = await Sender.Send(new StartAdUnlockCommand(request.Feature), cancellationToken);
        var location = result.IsSuccess
            ? $"{Request.PathBase}/api/v1/monetization/unlock-sessions/{result.Value.Id}"
            : string.Empty;
        return CreatedEnvelope(result, location);
    }

    /// <summary>Polled after each ad until <c>status</c> is <c>Granted</c>.</summary>
    [HttpGet("unlock-sessions/{sessionId:guid}")]
    [ProducesResponseType<ApiResponse<AdUnlockSessionResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetAdUnlockSession(Guid sessionId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdUnlockSessionQuery(sessionId), cancellationToken));

    /// <summary>No rewarded ad could be loaded: grants the unlock anyway, capped per day.</summary>
    /// <response code="403">Today's no-ad allowance is used (<c>AdUnlock.NoFillLimitReached</c>).</response>
    /// <response code="422">The session expired (<c>AdUnlock.SessionExpired</c>).</response>
    [HttpPost("unlock-sessions/{sessionId:guid}/no-fill")]
    [ProducesResponseType<ApiResponse<AdUnlockSessionResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status422UnprocessableEntity, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CompleteWithoutAds(Guid sessionId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new CompleteAdUnlockWithoutAdsCommand(sessionId), cancellationToken));
}
