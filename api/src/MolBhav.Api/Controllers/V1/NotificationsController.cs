using MediatR;
using Microsoft.AspNetCore.Mvc;
using Asp.Versioning;
using MolBhav.Api.Contracts;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Notification.GetMyNotifications;
using MolBhav.Application.Features.Notification.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>The signed-in user's notification inbox (BRD §14). Requires a signed-in user (fallback auth policy).</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/notifications")]
public sealed class NotificationsController(ISender sender) : ApiControllerBase(sender)
{
    [HttpGet]
    [ProducesResponseType<ApiResponse<PagedResult<NotificationResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyNotifications(
        [FromQuery] int page = 1, [FromQuery] int pageSize = PageRequest.DefaultPageSize, CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetMyNotificationsQuery(page, pageSize), cancellationToken));
}
