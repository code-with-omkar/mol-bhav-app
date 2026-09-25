namespace MolBhav.Application.Abstractions.Authentication;

/// <summary>Issues access tokens (no PII such as the phone number is placed in the token) and opaque refresh tokens (refresh tokens are stored hashed, never in plain text).</summary>
public interface IJwtTokenService
{
    AccessToken CreateAccessToken(TokenSubject subject);

    RefreshToken CreateRefreshToken();

    /// <summary>Deterministic one-way hash used to look up a presented refresh token.</summary>
    string HashRefreshToken(string refreshToken);
}

public sealed record TokenSubject(
    Guid UserId,
    IReadOnlyCollection<string> Roles,
    string SubscriptionTier,
    string PreferredLanguage);

public sealed record AccessToken(string Token, DateTimeOffset ExpiresAtUtc);

/// <param name="Token">Plain value returned to the client once.</param>
/// <param name="TokenHash">Value persisted server-side.</param>
/// <param name="ExpiresAtUtc">Absolute expiry; rotation issues a new token and revokes the presented one.</param>
public sealed record RefreshToken(string Token, string TokenHash, DateTimeOffset ExpiresAtUtc);
