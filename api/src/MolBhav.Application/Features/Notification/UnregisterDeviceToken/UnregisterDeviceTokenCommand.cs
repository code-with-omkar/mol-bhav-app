using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Notification.UnregisterDeviceToken;

/// <summary>Removes a device push token for the signed-in user. Idempotent — no error if the token does not exist.</summary>
public sealed record UnregisterDeviceTokenCommand(string Token) : ICommand;
