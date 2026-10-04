using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Notification.Admin.SendTestOpsAlert;

/// <summary>
/// Admin: sends a harmless test alert through the configured ops alert channel, so a new or rotated Slack webhook can
/// be proven before a real payment problem depends on it.
/// </summary>
public sealed record SendTestOpsAlertCommand : ICommand<OpsAlertTestResponse>;

/// <param name="Channel">Where the alert went: <c>slack</c>, or <c>log</c> when no channel is configured.</param>
/// <param name="SentAtUtc">When the alert was sent.</param>
public sealed record OpsAlertTestResponse(string Channel, DateTimeOffset SentAtUtc);
