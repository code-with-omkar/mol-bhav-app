namespace MolBhav.Application.Features.Identity;

/// <summary>Tokens issued by a successful login (any method) plus first-screen routing hints — see <c>VerifyOtpResponse</c>.</summary>
public sealed record LoginSessionResponse(
    Guid UserId,
    string AccessToken,
    DateTimeOffset AccessTokenExpiresAtUtc,
    string RefreshToken,
    DateTimeOffset RefreshTokenExpiresAtUtc,
    bool IsNewUser,
    bool IsOnboarded);
