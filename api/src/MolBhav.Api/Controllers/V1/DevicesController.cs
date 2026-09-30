using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Notification;
using MolBhav.Application.Features.Notification.RegisterDeviceToken;
using MolBhav.Application.Features.Notification.UnregisterDeviceToken;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Device token registration for push notifications.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/devices")]
public sealed class DevicesController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>Registers a device push token for the signed-in user. Idempotent.</summary>
    /// <response code="204">Token registered (or already existed).</response>
    [HttpPost]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Register(
        [FromBody] RegisterDeviceTokenRequest request,
        CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(
            new RegisterDeviceTokenCommand(request.Token, request.Platform),
            cancellationToken));

    /// <summary>Removes a device push token (e.g. on logout). Idempotent.</summary>
    /// <response code="204">Token removed (or was not registered).</response>
    [HttpDelete("{token}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Unregister(
        string token,
        CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(
            new UnregisterDeviceTokenCommand(Uri.UnescapeDataString(token)),
            cancellationToken));
}
