using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Net.Mime;
using MolBhav.Api.Contracts;
using MolBhav.Api.Setup;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Notification.Admin.GetAdminNotifications;
using MolBhav.Application.Features.Notification.Models;
using MolBhav.Domain.Notification;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Read-only delivery monitoring for the notification queue (BRD §14). Admin role only.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/notifications")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminNotificationsController(ISender sender) : ApiControllerBase(sender)
{
    [HttpGet]
    [ProducesResponseType<ApiResponse<PagedResult<AdminNotificationResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetNotifications(
        [FromQuery] Guid? userId,
        [FromQuery] NotificationChannel? channel,
        [FromQuery] NotificationStatus? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize,
        CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetAdminNotificationsQuery(userId, channel, status, page, pageSize), cancellationToken));
}
