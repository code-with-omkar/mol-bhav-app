using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Notification.GetNotificationPreferences;

/// <summary>Returns the signed-in user's notification preferences, with defaults if none have been saved yet.</summary>
public sealed record GetNotificationPreferencesQuery : IQuery<NotificationPreferencesResponse>;
