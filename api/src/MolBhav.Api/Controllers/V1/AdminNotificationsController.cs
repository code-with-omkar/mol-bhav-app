using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Net.Mime;
using MolBhav.Api.Contracts;
using MolBhav.Api.Setup;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Notification.Admin.GetAdminNotifications;
using MolBhav.Application.Features.Notification.Admin.SendTestOpsAlert;
using MolBhav.Application.Features.Notification.Models;
using MolBhav.Domain.Notification;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Read-only delivery monitoring for the notification queue (BRD §14), plus an ops-alert channel test. Admin role only.</summary>
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

    /// <summary>
    /// Sends a test alert through the ops alert channel (Slack when <c>OpsAlerts:SlackWebhookUrl</c> is set, otherwise
    /// the log). Use after configuring or rotating the webhook URL; <c>channel</c> in the response says which was used.
    /// </summary>
    /// <response code="502">The channel rejected the alert or was unreachable (<c>OpsAlerts.DeliveryFailed</c>); the API log has the reason.</response>
    [HttpPost("ops-alerts/test")]
    [ProducesResponseType<ApiResponse<OpsAlertTestResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status502BadGateway, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> SendTestOpsAlert(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new SendTestOpsAlertCommand(), cancellationToken));
}
