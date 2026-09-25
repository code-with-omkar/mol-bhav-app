using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Identity.VerifyOtp;

/// <summary>
/// <see cref="Outcome"/> carries the business result. Tokens are populated only when <see cref="Outcome"/> is
/// <see cref="OtpVerificationOutcome.Verified"/>. The controller maps <see cref="Outcome"/> to the HTTP status —
/// see <c>VerifyOtpCommandHandler</c> for why a wrong code is still a committed <c>Result.Success</c>.
/// <see cref="IsOnboarded"/> drives post-login routing: false → onboarding (category/profile) screen, true → home.
/// It is not the same as <see cref="IsNewUser"/>: a user who registered but quit before onboarding is not new but not onboarded.
/// </summary>
public sealed record VerifyOtpResponse(
    OtpVerificationOutcome Outcome,
    Guid? UserId,
    string? AccessToken,
    DateTimeOffset? AccessTokenExpiresAtUtc,
    string? RefreshToken,
    DateTimeOffset? RefreshTokenExpiresAtUtc,
    bool IsNewUser,
    bool IsOnboarded);
