using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Notification;

namespace MolBhav.Application.Features.Notification.RegisterDeviceToken;

/// <summary>Registers a device push token for the signed-in user. Idempotent — re-registering the same token is a no-op.</summary>
public sealed record RegisterDeviceTokenCommand(string Token, DevicePlatform Platform) : ICommand;
