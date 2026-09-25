namespace MolBhav.Api.Contracts.Identity;

/// <summary>Returned by "send code". The app shows a countdown of <see cref="ResendCooldownSeconds"/> before enabling "resend".</summary>
public sealed record OtpSentResponse(DateTimeOffset ExpiresAtUtc, int ResendCooldownSeconds);

/// <summary>
/// Session issued by a successful OTP verification or refresh. Store both tokens in secure storage
/// (flutter_secure_storage); send <see cref="AccessToken"/> as <c>Authorization: Bearer</c>; on 401 call refresh once;
/// if refresh returns 401, clear tokens and return to login. The refresh token is single-use — always replace the stored one.
/// </summary>
public sealed record SessionResponse(
    Guid UserId,
    string AccessToken,
    DateTimeOffset AccessTokenExpiresAtUtc,
    string RefreshToken,
    DateTimeOffset RefreshTokenExpiresAtUtc);

/// <summary>Login result: the session plus routing hints for the first screen after login.</summary>
/// <param name="Session">Tokens to store.</param>
/// <param name="IsNewUser">Account was created by this login.</param>
/// <param name="IsOnboarded">False → show onboarding (category + profile) before home.</param>
public sealed record LoginResponse(SessionResponse Session, bool IsNewUser, bool IsOnboarded);
