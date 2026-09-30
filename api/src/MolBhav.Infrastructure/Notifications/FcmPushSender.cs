using FirebaseAdmin.Messaging;
using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Notification;

namespace MolBhav.Infrastructure.Notifications;

/// <summary>Sends push notifications via Firebase Cloud Messaging (FCM). Stale/unregistered tokens are automatically
/// removed after a multicast send so the token table stays clean without a separate job.</summary>
internal sealed partial class FcmPushSender(
    FirebaseMessaging firebaseMessaging,
    IDeviceTokenRepository tokenRepository,
    ILogger<FcmPushSender> logger) : INotificationSender
{
    public async Task<bool> SendAsync(NotificationMessage notification, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(notification);

        var tokens = await tokenRepository.GetTokensByUserIdAsync(notification.UserId, cancellationToken);
        if (tokens.Count == 0)
        {
            LogNoTokens(logger, notification.UserId);
            return true; // Nothing to deliver — not a failure.
        }

        var message = new MulticastMessage
        {
            Tokens = tokens,
            Notification = new Notification
            {
                Title = notification.Title,
                Body = notification.Body,
            },
        };

        var result = await firebaseMessaging.SendEachForMulticastAsync(message, cancellationToken);

        var staleTokens = new List<string>();
        for (var i = 0; i < result.Responses.Count; i++)
        {
            var response = result.Responses[i];
            if (!response.IsSuccess &&
                response.Exception?.MessagingErrorCode == MessagingErrorCode.Unregistered)
            {
                staleTokens.Add(tokens[i]);
            }
        }

        if (staleTokens.Count > 0)
        {
            LogStaleTokens(logger, staleTokens.Count, notification.UserId);
            await tokenRepository.RemoveStaleAsync(staleTokens, cancellationToken);
        }

        return result.SuccessCount > 0;
    }

    [LoggerMessage(Level = LogLevel.Debug, Message = "No device tokens for user {UserId} — push skipped.")]
    private static partial void LogNoTokens(ILogger logger, Guid userId);

    [LoggerMessage(Level = LogLevel.Information, Message = "Removed {Count} stale FCM token(s) for user {UserId}.")]
    private static partial void LogStaleTokens(ILogger logger, int count, Guid userId);
}
