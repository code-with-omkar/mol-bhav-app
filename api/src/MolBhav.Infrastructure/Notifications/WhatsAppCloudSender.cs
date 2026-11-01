using System.Net.Http.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Notification;

namespace MolBhav.Infrastructure.Notifications;

/// <summary>Sends WhatsApp template messages to the user's registered mobile via the Meta Cloud API.</summary>
internal sealed partial class WhatsAppCloudSender(
    IHttpClientFactory httpClientFactory,
    IOptions<WhatsAppOptions> options,
    IUserRepository users,
    ILogger<WhatsAppCloudSender> logger) : INotificationSender
{
    public const string HttpClientName = "whatsapp";

    /// <summary>Template variables may not hold new lines, tabs or more than four spaces in a row.</summary>
    private const int ParameterMaxLength = 1024;

    public async Task<bool> SendAsync(NotificationMessage notification, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(notification);

        var opts = options.Value;
        var user = await users.GetByIdAsync(notification.UserId, cancellationToken);
        if (user is null)
        {
            LogUserNotFound(logger, notification.UserId);
            return false;
        }

        // WhatsApp expects digits only with the country code, e.g. 919876543210.
        var to = user.PhoneNumber.Value.TrimStart('+');

        object[] parameters = opts.BodyParameterCount switch
        {
            <= 0 => [],
            1 => [Parameter($"{notification.Title}: {notification.Body}")],
            _ => [Parameter(notification.Title), Parameter(notification.Body)],
        };

        var template = parameters.Length == 0
            ? (object)new { name = opts.TemplateName, language = new { code = opts.TemplateLanguage } }
            : new
            {
                name = opts.TemplateName,
                language = new { code = opts.TemplateLanguage },
                components = new[] { new { type = "body", parameters } },
            };

        var payload = new { messaging_product = "whatsapp", to, type = "template", template };

        var client = httpClientFactory.CreateClient(HttpClientName);
        using var response = await client.PostAsJsonAsync(
            $"{opts.ApiVersion}/{opts.PhoneNumberId}/messages", payload, cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            throw new NotificationDeliveryException("WhatsApp", (int)response.StatusCode, body);
        }

        // A 200 only means Meta accepted the message. Delivery, or a failure such as 131026 / 131049, is reported
        // later through the webhook, so log the ids needed to trace the message in WhatsApp Manager.
        var accepted = await response.Content.ReadFromJsonAsync<SendResponse>(cancellationToken);
        var messageId = accepted?.Messages?.FirstOrDefault()?.Id;
        if (!string.IsNullOrWhiteSpace(messageId))
        {
            // Saved with the notification, so the delivery webhook can find it again.
            notification.AttachProviderMessageId(messageId);
        }

        LogSent(
            logger,
            notification.Id,
            notification.UserId,
            messageId ?? "?",
            accepted?.Contacts?.FirstOrDefault()?.WaId ?? "?",
            Mask(to));
        return true;
    }

    private static object Parameter(string text) => new { type = "text", text = Clean(text) };

    private static string Clean(string text)
    {
        var flat = WhitespaceRun().Replace(text.Replace('\n', ' ').Replace('\r', ' ').Replace('\t', ' '), " ").Trim();
        return flat.Length <= ParameterMaxLength ? flat : flat[..ParameterMaxLength];
    }

    /// <summary>Keeps the last four digits only — full phone numbers never go to the logs.</summary>
    private static string Mask(string digits) =>
        digits.Length <= 4 ? digits : new string('*', digits.Length - 4) + digits[^4..];

    [GeneratedRegex(" {2,}")]
    private static partial Regex WhitespaceRun();

    private sealed record SendResponse(
        [property: JsonPropertyName("contacts")] IReadOnlyList<SendContact>? Contacts,
        [property: JsonPropertyName("messages")] IReadOnlyList<SendMessageId>? Messages);

    private sealed record SendContact([property: JsonPropertyName("wa_id")] string? WaId);

    private sealed record SendMessageId([property: JsonPropertyName("id")] string? Id);

    [LoggerMessage(Level = LogLevel.Warning, Message = "WhatsApp sender: user {UserId} not found — message skipped.")]
    private static partial void LogUserNotFound(ILogger logger, Guid userId);

    [LoggerMessage(
        Level = LogLevel.Information,
        Message = "WhatsApp message {NotificationId} accepted by Meta for user {UserId}: wamid {MessageId}, wa_id {WaId}, to {To}.")]
    private static partial void LogSent(
        ILogger logger, Guid notificationId, Guid userId, string messageId, string waId, string to);
}
