namespace MolBhav.Application.Abstractions.Authentication;

/// <summary>
/// Validates a Google ID token sent by the app: Google's signature (rotating public keys), issuer, expiry and that the
/// audience is one of our OAuth client ids. Returns null for anything that does not validate — callers never see why
/// (no oracle for forged tokens).
/// </summary>
public interface IGoogleIdTokenVerifier
{
    Task<GoogleIdentity?> VerifyAsync(string idToken, CancellationToken cancellationToken = default);
}

/// <param name="Subject">Google's stable account id (<c>sub</c>) — the only value used to match accounts.</param>
/// <param name="Email">Shown on the profile; never used to match or link accounts.</param>
/// <param name="EmailVerified">Google has verified the email; unverified emails are not stored.</param>
/// <param name="Name">Pre-fills the display name of a new account.</param>
public sealed record GoogleIdentity(string Subject, string? Email, bool EmailVerified, string? Name);
