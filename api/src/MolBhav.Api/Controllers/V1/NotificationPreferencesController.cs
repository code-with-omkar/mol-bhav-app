using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Notification;
using MolBhav.Application.Features.Notification.GetNotificationPreferences;
using MolBhav.Application.Features.Notification.UpdateNotificationPreferences;

namespace MolBhav.Api.Controllers.V1;

/// <summary>The signed-in user's notification delivery preferences.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/notification-preferences")]
public sealed class NotificationPreferencesController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>Returns the current notification preferences, using all-on defaults when nothing has been saved yet.</summary>
    [HttpGet]
    [ProducesResponseType<ApiResponse<NotificationPreferencesResponse>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> Get(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetNotificationPreferencesQuery(), cancellationToken));

    /// <summary>Saves the user's notification delivery preferences. Creates the row if it does not exist yet.</summary>
    /// <response code="200">Saved.</response>
    /// <response code="400">Sub-toggle enabled while its master toggle is off.</response>
    [HttpPut]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<NotificationPreferencesResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Update(
        [FromBody] UpdateNotificationPreferencesRequest request,
        CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(
            new UpdateNotificationPreferencesCommand(
                request.PushEnabled,
                request.AlertPushEnabled,
                request.PriceUpdatePushEnabled,
                request.WhatsAppEnabled,
                request.AlertWhatsAppEnabled),
            cancellationToken));
}
