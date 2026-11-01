using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Setup;
using MolBhav.Application.Features.FeatureSwitches.GetFeatureSwitches;
using MolBhav.Application.Features.FeatureSwitches.Models;
using MolBhav.Application.Features.FeatureSwitches.SetFeatureSwitch;
using MolBhav.Domain.FeatureSwitches;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// Which optional parts of the app are on for everyone (ads, reports, cost estimator). Anyone may read the list so the
/// app can hide a switched-off part from its first screen; only an admin can change it.
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/app-features")]
public sealed class AppFeaturesController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>Every feature with whether it is on. A feature nobody has switched off is on.</summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType<ApiResponse<IReadOnlyList<FeatureSwitchResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> List(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetFeatureSwitchesQuery(), cancellationToken));

    /// <summary>Admin: turn a feature on or off for every user.</summary>
    [HttpPut("{feature}")]
    [Authorize(Policy = AuthorizationPolicies.Admin)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Set(AppFeature feature, [FromBody] SetFeatureSwitchRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new SetFeatureSwitchCommand(feature, request.Enabled), cancellationToken));
}
