using System.Globalization;
using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Notification.Admin.SendTestOpsAlert;

/// <summary>
/// A delivery failure is returned as <see cref="DeliveryFailed"/> (Unavailable) instead of a success, so the admin sees
/// that the channel is broken; the sender has already logged the channel's own reason (e.g. Slack's <c>no_service</c>).
/// </summary>
internal sealed partial class SendTestOpsAlertCommandHandler(
    IOpsAlertSender opsAlerts,
    ICurrentUser currentUser,
    TimeProvider timeProvider,
    ILogger<SendTestOpsAlertCommandHandler> logger) : ICommandHandler<SendTestOpsAlertCommand, OpsAlertTestResponse>
{
    public static readonly Error DeliveryFailed = Error.Unavailable(
        "OpsAlerts.DeliveryFailed",
        "The alert channel rejected or could not be reached for the test alert. The API log has the channel's reason.");

    public async Task<Result<OpsAlertTestResponse>> Handle(SendTestOpsAlertCommand request, CancellationToken cancellationToken)
    {
        var nowUtc = timeProvider.GetUtcNow();
        var adminId = currentUser.UserId;

        var alert = new OpsAlert(
            "Test alert — the ops alert channel works",
            [
                new("Requested by admin", adminId?.ToString() ?? "unknown"),
                new("Sent at (UTC)", nowUtc.ToString("u", CultureInfo.InvariantCulture)),
                new("Action", "None. Real alerts here mean a payment webhook was parked and needs review."),
            ]);

        var delivered = await opsAlerts.SendAsync(alert, cancellationToken);
        LogTestAlert(logger, opsAlerts.Channel, delivered, adminId);

        if (!delivered)
        {
            return DeliveryFailed;
        }

        return new OpsAlertTestResponse(opsAlerts.Channel, nowUtc);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Test ops alert via {Channel} by admin {AdminUserId}: delivered = {Delivered}")]
    private static partial void LogTestAlert(ILogger logger, string channel, bool delivered, Guid? adminUserId);
}
