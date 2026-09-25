using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Identity.RefreshToken;

/// <summary>Tokens are populated only when <see cref="Outcome"/> is <see cref="RefreshTokenOutcome.Rotated"/>.</summary>
public sealed record RefreshTokenResponse(
    RefreshTokenOutcome Outcome,
    Guid? UserId,
    string? AccessToken,
    DateTimeOffset? AccessTokenExpiresAtUtc,
    string? RefreshToken,
    DateTimeOffset? RefreshTokenExpiresAtUtc);
