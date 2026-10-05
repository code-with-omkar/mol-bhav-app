using MolBhav.Domain.Common.Exceptions;

namespace MolBhav.Domain.Identity;

/// <summary>
/// A third-party identity (e.g. a Google account) linked to a <see cref="User"/>. Keyed by (provider, subject): the
/// provider's stable account id, never the email — emails can change or be reassigned. A given Google account belongs
/// to at most one user; a user holds at most one login per provider.
/// </summary>
public sealed class UserExternalLogin
{
    public const int SubjectMaxLength = 255;
    public const int EmailMaxLength = 320;

    private UserExternalLogin(ExternalLoginProvider provider, string subject, string? email, DateTimeOffset linkedAtUtc)
    {
        Provider = provider;
        Subject = subject;
        Email = email;
        LinkedAtUtc = linkedAtUtc;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private UserExternalLogin()
    {
        Subject = string.Empty;
    }

    public ExternalLoginProvider Provider { get; private init; }

    /// <summary>The provider's immutable account id (Google's <c>sub</c> claim).</summary>
    public string Subject { get; private init; }

    /// <summary>Shown on the profile ("Signed in with Google as …"); informational only, never used to match accounts.</summary>
    public string? Email { get; private set; }

    public DateTimeOffset LinkedAtUtc { get; private init; }

    internal static UserExternalLogin Create(ExternalLoginProvider provider, string subject, string? email, DateTimeOffset linkedAtUtc)
    {
        if (string.IsNullOrWhiteSpace(subject) || subject.Length > SubjectMaxLength)
        {
            throw new DomainException("User.ExternalLoginSubjectInvalid", "The provider account id is missing or too long.");
        }

        return new UserExternalLogin(provider, subject.Trim(), NormaliseEmail(email), linkedAtUtc);
    }

    /// <summary>Keeps the shown email current when the user changes it at the provider.</summary>
    internal void RefreshEmail(string? email) => Email = NormaliseEmail(email);

    private static string? NormaliseEmail(string? email)
    {
        var trimmed = email?.Trim();
        return string.IsNullOrEmpty(trimmed) || trimmed.Length > EmailMaxLength ? null : trimmed.ToLowerInvariant();
    }
}
