namespace MolBhav.Domain.Identity;

/// <summary>Business outcome of presenting a refresh token to <see cref="RefreshTokenGrant"/> rotation.</summary>
public enum RefreshTokenOutcome
{
    Rotated = 0,
    Expired = 1,

    /// <summary>The presented token had already been rotated away — a strong signal of theft/replay (OWASP ASVS 3.3.1). The whole token family is revoked.</summary>
    ReuseDetected = 2,

    /// <summary>
    /// The token was rotated a moment ago by a parallel request from the same client (two calls refreshing at once).
    /// Benign: the client should retry with the refresh token it has just stored. Nothing is revoked.
    /// </summary>
    Superseded = 3,
}
