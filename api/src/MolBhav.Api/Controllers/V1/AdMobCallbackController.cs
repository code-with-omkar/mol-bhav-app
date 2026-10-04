using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using MolBhav.Api.Setup;
using MolBhav.Application.Features.Monetization.RecordRewardedAdView;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// AdMob's rewarded-ad server-side-verification callback. Anonymous by necessity (Google calls it); every request is
/// authenticated by its ECDSA signature instead. Set this URL as the rewarded ad unit's SSV callback in the AdMob console.
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/ads/admob")]
[ApiExplorerSettings(IgnoreApi = true)]
public sealed class AdMobCallbackController(ISender sender) : ApiControllerBase(sender)
{
    /// <response code="204">Authentic callback acknowledged (counted, or harmlessly ignored).</response>
    /// <response code="403">Signature missing or invalid (<c>AdMob.InvalidCallback</c>).</response>
    [HttpGet("ssv")]
    [AllowAnonymous]
    [EnableRateLimiting(RateLimitPolicies.AdCallback)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> RewardedAdCallback(CancellationToken cancellationToken) =>
        // The raw query, not model-bound values: the signature covers the exact bytes AdMob sent.
        NoContentOrProblem(await Sender.Send(new RecordRewardedAdViewCommand(Request.QueryString.Value ?? string.Empty), cancellationToken));
}
