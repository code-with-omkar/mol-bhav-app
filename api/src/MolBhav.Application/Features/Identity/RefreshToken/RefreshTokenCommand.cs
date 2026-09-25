using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.RefreshToken;

/// <summary>Silent re-auth called by the mobile app when the access token nears expiry. Anonymous (the refresh token itself is the credential).</summary>
public sealed record RefreshTokenCommand(string RefreshToken) : ICommand<RefreshTokenResponse>;
