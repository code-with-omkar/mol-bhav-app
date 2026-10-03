using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Identity;

/// <summary>
/// Stable error codes for the login screens. OTP failures deliberately never map to 401: the mobile HTTP client
/// treats 401 as "access token expired → refresh", which is wrong on the anonymous login endpoints. Refresh failures
/// DO map to 401 — that is the client's signal to drop its tokens and return to the login screen — except the benign
/// concurrent-refresh race, which is 409 ("retry with the token you just stored", never "log out").
/// </summary>
public static class IdentityErrors
{
    public static readonly Error LoginMethodDisabled =
        Error.Forbidden("Auth.MethodDisabled", "This sign-in method is not available.");

    public static readonly Error InvalidCredentials =
        Error.Validation("Auth.InvalidCredentials", "Incorrect mobile number or password.");

    public static readonly Error AccountAlreadyExists =
        Error.Conflict("Auth.AccountExists", "An account with this mobile number already exists. Log in instead.");

    public static Error LockedOut(DateTimeOffset? lockedUntilUtc, DateTimeOffset nowUtc)
    {
        var minutes = lockedUntilUtc is { } until ? Math.Max(1, (int)Math.Ceiling((until - nowUtc).TotalMinutes)) : 15;
        return Error.BusinessRule(
            "Auth.LockedOut",
            $"Too many incorrect attempts. Try again in {minutes} minute{(minutes == 1 ? string.Empty : "s")}.");
    }

    public static Error ForOtpOutcome(OtpVerificationOutcome outcome) => outcome switch
    {
        OtpVerificationOutcome.IncorrectCode =>
            Error.Validation("Otp.Incorrect", "The verification code is incorrect."),
        OtpVerificationOutcome.Expired =>
            Error.BusinessRule("Otp.Expired", "The verification code has expired. Request a new code."),
        OtpVerificationOutcome.AlreadyUsed =>
            Error.BusinessRule("Otp.AlreadyUsed", "This verification code has already been used. Request a new code."),
        OtpVerificationOutcome.TooManyAttempts =>
            Error.BusinessRule("Otp.TooManyAttempts", "Too many incorrect attempts. Request a new code."),
        _ => throw new ArgumentOutOfRangeException(nameof(outcome), outcome, "Verified is not an error outcome."),
    };

    public static Error ForRefreshOutcome(RefreshTokenOutcome outcome) => outcome switch
    {
        RefreshTokenOutcome.Expired =>
            Error.Unauthorized("RefreshToken.Expired", "Your session has expired. Please log in again."),
        RefreshTokenOutcome.ReuseDetected =>
            Error.Unauthorized("RefreshToken.Revoked", "Your session is no longer valid. Please log in again."),
        RefreshTokenOutcome.Superseded =>
            Error.Conflict("RefreshToken.Superseded", "This refresh token was just rotated by a parallel request. Retry with the latest stored token."),
        _ => throw new ArgumentOutOfRangeException(nameof(outcome), outcome, "Rotated is not an error outcome."),
    };
}
