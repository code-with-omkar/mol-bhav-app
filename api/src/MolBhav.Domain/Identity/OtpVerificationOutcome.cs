namespace MolBhav.Domain.Identity;

/// <summary>Business outcome of presenting a code against an <see cref="OtpChallenge"/>.</summary>
public enum OtpVerificationOutcome
{
    Verified = 0,
    IncorrectCode = 1,
    Expired = 2,
    AlreadyUsed = 3,
    TooManyAttempts = 4,
}
