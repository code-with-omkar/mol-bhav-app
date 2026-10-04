using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Notifications;

namespace MolBhav.Infrastructure.Notifications.OpsAlerts;

/// <summary>
/// Used when no alert channel is configured: the alert is written to the log at Critical, so it still reaches
/// whatever watches the logs. Configure <c>OpsAlerts:SlackWebhookUrl</c> to get it in front of a person.
/// </summary>
internal sealed partial class LoggingOpsAlertSender(ILogger<LoggingOpsAlertSender> logger) : IOpsAlertSender
{
    public Task SendAsync(OpsAlert alert, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(alert);

        if (logger.IsEnabled(LogLevel.Critical))
        {
            var details = string.Join("; ", alert.Details.Select(d => $"{d.Key}: {d.Value}"));
            LogAlert(logger, alert.Title, details);
        }

        return Task.CompletedTask;
    }

    [LoggerMessage(Level = LogLevel.Critical, Message = "OPS ALERT (no alert channel configured): {Title} — {Details}")]
    private static partial void LogAlert(ILogger logger, string title, string details);
}
