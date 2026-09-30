using MolBhav.Domain.Notification;

namespace MolBhav.Api.Contracts.Notification;

public sealed record RegisterDeviceTokenRequest(string Token, DevicePlatform Platform);
