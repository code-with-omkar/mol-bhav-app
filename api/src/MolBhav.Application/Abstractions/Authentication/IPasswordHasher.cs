namespace MolBhav.Application.Abstractions.Authentication;

/// <summary>One-way, salted, deliberately slow password hashing (implementation in Infrastructure).</summary>
public interface IPasswordHasher
{
    /// <summary>Produces a self-describing hash (algorithm, work factor, salt, digest) safe to persist.</summary>
    string Hash(string password);

    /// <summary>
    /// Checks <paramref name="password"/> against <paramref name="passwordHash"/>. A null hash (unknown account or an
    /// OTP-only account) still performs a full-cost derivation and returns <see cref="PasswordVerificationResult.Failed"/>,
    /// so response timing does not reveal whether a mobile number is registered.
    /// </summary>
    PasswordVerificationResult Verify(string? passwordHash, string password);
}

public enum PasswordVerificationResult
{
    Failed = 0,
    Success = 1,

    /// <summary>Correct, but hashed with an older work factor — re-hash and store.</summary>
    SuccessRehashNeeded = 2,
}
