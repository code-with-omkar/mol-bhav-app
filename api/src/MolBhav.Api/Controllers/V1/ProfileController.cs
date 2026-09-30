using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Identity;
using MolBhav.Application.Features.Identity.GetProfile;
using MolBhav.Application.Features.Identity.UpdateProfile;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Onboarding and profile screens for the signed-in user (BRD §7). Always "me" — no user id in the route.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/profile")]
public sealed class ProfileController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>The signed-in user's profile. Phone number is returned masked.</summary>
    [HttpGet]
    [ProducesResponseType<ApiResponse<UserProfileResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Get(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetProfileQuery(), cancellationToken));

    /// <summary>
    /// Completes onboarding / saves the edit-profile screen. Full replacement of profile fields and categories.
    /// A changed preferred language takes effect in the access token on the next refresh.
    /// </summary>
    /// <response code="200">Saved.</response>
    /// <response code="400">Invalid language (<c>LanguageCode.Invalid</c>) or category code (<c>ProcurementCategoryCode.Invalid</c>).</response>
    [HttpPut]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<UpdateProfileResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Update([FromBody] UpdateProfileRequest request, CancellationToken cancellationToken)
    {
        var command = new UpdateProfileCommand(
            request.DisplayName,
            request.BusinessType,
            request.State,
            request.District,
            request.PreferredLanguage ?? string.Empty,
            request.Categories ?? []);

        return OkEnvelope(await Sender.Send(command, cancellationToken), "Profile saved.");
    }
}
