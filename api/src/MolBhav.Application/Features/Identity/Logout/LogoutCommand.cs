using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.Logout;

/// <summary>Revokes one refresh token (the device's) so it can no longer be used to obtain new access tokens. Requires authentication.</summary>
public sealed record LogoutCommand(string RefreshToken) : ICommand;
