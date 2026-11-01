using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Setup;
using MolBhav.Application.Features.AppNotices.GetAppNotice;
using MolBhav.Application.Features.AppNotices.Models;
using MolBhav.Application.Features.AppNotices.SetAppNotice;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// The one message shown to every user of the app (planned downtime, a known problem, maintenance). Anyone may read it,
/// so it can appear before sign-in and while the service is down for maintenance; only an admin can change it.
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/app-notice")]
public sealed class AppNoticeController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>The notice to show. When it is off, <c>isActive</c> is false and there is no text.</summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType<ApiResponse<AppNoticeResponse>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> Get(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAppNoticeQuery(), cancellationToken));

    /// <summary>Admin: the notice as saved, including the text of one that is switched off.</summary>
    [HttpGet("admin")]
    [Authorize(Policy = AuthorizationPolicies.Admin)]
    [ProducesResponseType<ApiResponse<AppNoticeResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetForEditing(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAppNoticeQuery(ForEditing: true), cancellationToken));

    /// <summary>Admin: turn the notice on or off, or change its type or text.</summary>
    [HttpPut]
    [Authorize(Policy = AuthorizationPolicies.Admin)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Set([FromBody] SetAppNoticeRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new SetAppNoticeCommand(request.IsActive, request.Severity, request.Message), cancellationToken));
}
