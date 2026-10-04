using System.ComponentModel.DataAnnotations;

namespace MolBhav.Infrastructure.Notifications.OpsAlerts;

internal sealed class OpsAlertOptions
{
    public const string SectionName = "OpsAlerts";

    /// <summary>
    /// Slack incoming-webhook URL. It is a credential (anyone holding it can post to the channel): set it with
    /// user-secrets or the <c>OpsAlerts__SlackWebhookUrl</c> environment variable, never in appsettings.
    /// Empty = alerts are written to the log only. Otherwise it must be an absolute https URL (checked at startup).
    /// </summary>
    public string? SlackWebhookUrl { get; set; }

    public bool HasValidSlackWebhookUrl =>
        string.IsNullOrWhiteSpace(SlackWebhookUrl)
        || (Uri.TryCreate(SlackWebhookUrl, UriKind.Absolute, out var uri) && uri.Scheme == Uri.UriSchemeHttps);

    /// <summary>Prefixed to every alert so alerts from staging and production are told apart in one channel.</summary>
    [Required]
    [MaxLength(30)]
    public string EnvironmentLabel { get; set; } = "MolBhav";
}
