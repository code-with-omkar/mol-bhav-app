using System.Net.Http.Json;
using System.Text;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Notifications;

namespace MolBhav.Infrastructure.Notifications.OpsAlerts;

/// <summary>
/// Posts alerts to a Slack incoming webhook (<c>{"text": "..."}</c>; Slack answers 200 <c>ok</c>, or a 4xx with a short
/// reason such as <c>no_service</c> or <c>channel_is_archived</c>). Failures are logged with that reason and swallowed —
/// the alert's facts are in the same log line, so nothing is lost if Slack is down. The webhook URL is a credential and
/// is never logged.
/// </summary>
internal sealed partial class SlackOpsAlertSender(
    IHttpClientFactory httpClientFactory,
    IOptions<OpsAlertOptions> options,
    ILogger<SlackOpsAlertSender> logger) : IOpsAlertSender
{
    public const string HttpClientName = "ops-alerts-slack";
    public const string ChannelName = "slack";

    /// <summary>Slack's error bodies are short codes (e.g. <c>no_service</c>, <c>channel_is_archived</c>); cap what we log.</summary>
    private const int MaxReasonLength = 200;

    public string Channel => ChannelName;

    public async Task<bool> SendAsync(OpsAlert alert, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(alert);

        var settings = options.Value;
        var text = Format(settings.EnvironmentLabel, alert);

        try
        {
            var client = httpClientFactory.CreateClient(HttpClientName);
            using var response = await client.PostAsJsonAsync(new Uri(settings.SlackWebhookUrl!), new { text }, cancellationToken);

            if (response.IsSuccessStatusCode)
            {
                return true;
            }

            var statusCode = (int)response.StatusCode;
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            var reason = body.Length <= MaxReasonLength ? body : body[..MaxReasonLength];
            LogRejected(logger, statusCode, reason, text);
            return false;
        }
        catch (Exception ex) when (ex is not OperationCanceledException || !cancellationToken.IsCancellationRequested)
        {
            var errorType = ex.GetType().Name;
            LogFailed(logger, errorType, text);
            return false;
        }
    }

    /// <summary>Slack mrkdwn: bold title line, then one line per detail. Values are escaped so ids can't inject markup.</summary>
    internal static string Format(string environmentLabel, OpsAlert alert)
    {
        var builder = new StringBuilder()
            .Append(":rotating_light: *[").Append(Escape(environmentLabel)).Append("] ").Append(Escape(alert.Title)).Append('*');

        foreach (var (label, value) in alert.Details)
        {
            builder.Append('\n').Append("• *").Append(Escape(label)).Append(":* ").Append(Escape(value));
        }

        return builder.ToString();
    }

    // Slack requires only these three to be escaped in message text.
    private static string Escape(string value) =>
        value.Replace("&", "&amp;", StringComparison.Ordinal)
            .Replace("<", "&lt;", StringComparison.Ordinal)
            .Replace(">", "&gt;", StringComparison.Ordinal);

    [LoggerMessage(Level = LogLevel.Critical, Message = "Ops alert rejected by Slack with HTTP {StatusCode} ({Reason}); alert was: {Alert}")]
    private static partial void LogRejected(ILogger logger, int statusCode, string reason, string alert);

    [LoggerMessage(Level = LogLevel.Critical, Message = "Ops alert could not be sent to Slack ({ErrorType}); alert was: {Alert}")]
    private static partial void LogFailed(ILogger logger, string errorType, string alert);
}
