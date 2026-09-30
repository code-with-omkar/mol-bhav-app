using System.Net.Http.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Notification;

namespace MolBhav.Infrastructure.Notifications;

/// <summary>Sends WhatsApp template messages via the Meta Graph API v19.0.</summary>
internal sealed partial class WhatsAppCloudSender(
    IHttpClientFactory httpClientFactory,
    IOptions<WhatsAppOptions> options,
    IUserRepository users,
    ILogger<WhatsAppCloudSender> logger) : INotificationSender
{
    public const string HttpClientName = "whatsapp";

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

        // Strip '+' — WhatsApp expects digits only, e.g. 919876543210
        var to = user.PhoneNumber.Value.TrimStart('+');

        var client = httpClientFactory.CreateClient(HttpClientName);

        var payload = new
        {
            messaging_product = "whatsapp",
            to,
            type = "template",
            template = new
            {
                name = opts.TemplateName,
                language = new { code = opts.TemplateLanguage },
                components = new[]
                {
                    new
                    {
                        type = "body",
                        parameters = new[]
                        {
                            new { type = "text", text = notification.Title },
                            new { type = "text", text = notification.Body },
                        },
                    },
                },
            },
        };

        using var response = await client.PostAsJsonAsync(
            $"{opts.PhoneNumberId}/messages", payload, cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            throw new NotificationDeliveryException("WhatsApp", (int)response.StatusCode, body);
        }

        return true;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "WhatsApp sender: user {UserId} not found — message skipped.")]
    private static partial void LogUserNotFound(ILogger logger, Guid userId);
}
