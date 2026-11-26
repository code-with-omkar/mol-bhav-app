namespace MolBhav.Api.Contracts.Identity;

// Request bodies are nullable on purpose: a missing field reaches FluentValidation (stable messages, one error
// shape) instead of being rejected earlier by MVC's implicit-required check on non-nullable reference types.

/// <param name="PhoneNumber">10-digit Indian mobile; +91/0 prefixes, spaces and dashes are accepted.</param>
public sealed record RequestOtpRequest(string? PhoneNumber);

/// <param name="PhoneNumber">The same number the code was sent to.</param>
/// <param name="Code">6-digit code.</param>
public sealed record VerifyOtpRequest(string? PhoneNumber, string? Code);

/// <param name="PhoneNumber">10-digit Indian mobile; +91/0 prefixes, spaces and dashes are accepted.</param>
/// <param name="Password">The account password (login) or the new password (register: 8–128 chars, a letter and a digit).</param>
public sealed record PasswordCredentialsRequest(string? PhoneNumber, string? Password);

/// <param name="IdToken">Google ID token from Google Sign-In on the device.</param>
/// <param name="PhoneNumber">Only when creating an account (after <c>Auth.PhoneRequired</c>): 10-digit Indian mobile.</param>
public sealed record GoogleLoginRequest(string? IdToken, string? PhoneNumber);

/// <param name="IdToken">Google ID token from Google Sign-In on the device.</param>
public sealed record GoogleLinkRequest(string? IdToken);

/// <param name="PhoneNumber">The account's mobile number.</param>
public sealed record ForgotPasswordRequest(string? PhoneNumber);

/// <param name="PhoneNumber">The account's mobile number.</param>
/// <param name="Code">The code sent to that number.</param>
/// <param name="NewPassword">8–128 chars, a letter and a digit.</param>
public sealed record ResetForgottenPasswordRequest(string? PhoneNumber, string? Code, string? NewPassword);

/// <param name="CurrentPassword">Required when the account already has a password; omit it to set a first password.</param>
/// <param name="NewPassword">8–128 chars, a letter and a digit.</param>
public sealed record ChangePasswordRequest(string? CurrentPassword, string? NewPassword);

public sealed record RefreshTokenRequest(string? RefreshToken);

public sealed record LogoutRequest(string? RefreshToken);
