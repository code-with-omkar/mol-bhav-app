namespace MolBhav.Application.Abstractions.Authentication;

/// <summary>
/// Which sign-in methods this deployment accepts (configuration, see <c>Authentication:LoginMethods</c>). OTP costs money
/// per SMS (and needs DLT registration in India), so it can be switched off while password login stays free.
/// </summary>
public interface ILoginMethods
{
    bool OtpEnabled { get; }

    bool PasswordEnabled { get; }

    /// <summary>
    /// Development-only escape hatch: lets "create account" set a password on an existing OTP-only account. Refused at
    /// startup outside Development, because without OTP nothing proves the caller owns that number.
    /// </summary>
    bool AllowClaimingPasswordlessAccounts { get; }

    /// <summary>"Sign in with Google" — needs <see cref="GoogleServerClientId"/>.</summary>
    bool GoogleEnabled { get; }

    /// <summary>
    /// The Google OAuth <i>web</i> client id. Public (it ships in every app build); the app passes it to Google Sign-In
    /// so the ID token it receives is issued for this backend. Null when Google sign-in is off.
    /// </summary>
    string? GoogleServerClientId { get; }
}
