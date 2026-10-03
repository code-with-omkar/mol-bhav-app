using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.PasswordLogin;

/// <summary>Login screen — mobile number + password. Anonymous. Requires <c>ILoginMethods.PasswordEnabled</c>.</summary>
public sealed record LoginWithPasswordCommand(string PhoneNumber, string Password) : ICommand<PasswordLoginResponse>;

public enum PasswordLoginOutcome
{
    Succeeded = 0,

    /// <summary>Unknown number, OTP-only account or wrong password — deliberately indistinguishable.</summary>
    InvalidCredentials = 1,

    LockedOut = 2,
}

/// <summary>
/// Like <c>VerifyOtpResponse</c>, a wrong password is a committed <c>Result.Success</c> with a non-success
/// <see cref="Outcome"/>: the failed-attempt counter must be persisted, and the unit of work commits only on success.
/// </summary>
public sealed record PasswordLoginResponse(
    PasswordLoginOutcome Outcome,
    LoginSessionResponse? Session,
    DateTimeOffset? LockedUntilUtc);
