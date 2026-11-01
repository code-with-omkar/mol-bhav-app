using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Setup;
using MolBhav.Application.Features.AppVersions.GetAppVersionPolicy;
using MolBhav.Application.Features.AppVersions.Models;
using MolBhav.Application.Features.AppVersions.SetAppVersionPolicy;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// The oldest app version still allowed to run. Anyone may read it (the app checks before sign-in); only an admin can
/// change it. Admins are never blocked by it in the app, so a wrong value can always be fixed.
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/app-version")]
public sealed class AppVersionController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>The minimum version and update link; both null until an admin sets them.</summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType<ApiResponse<AppVersionPolicyResponse>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> Get(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAppVersionPolicyQuery(), cancellationToken));

    /// <summary>Admin: set the minimum version (empty clears it) and the update link.</summary>
    [HttpPut]
    [Authorize(Policy = AuthorizationPolicies.Admin)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Set([FromBody] SetAppVersionPolicyRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new SetAppVersionPolicyCommand(request.MinimumVersion, request.UpdateUrl), cancellationToken));
}
