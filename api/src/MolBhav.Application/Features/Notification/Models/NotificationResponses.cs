using MolBhav.Domain.Notification;

namespace MolBhav.Application.Features.Notification.Models;

public sealed record NotificationResponse(
    Guid Id,
    NotificationChannel Channel,
    string Title,
    string Body,
    NotificationStatus Status,
    DateTimeOffset? SentAtUtc,
    DateTimeOffset CreatedAtUtc);

public sealed record AdminNotificationResponse(
    Guid Id,
    Guid UserId,
    NotificationChannel Channel,
    string Title,
    NotificationStatus Status,
    string? FailureReason,
    DateTimeOffset? SentAtUtc,
    DateTimeOffset CreatedAtUtc);
