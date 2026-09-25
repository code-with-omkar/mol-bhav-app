namespace MolBhav.Application.Features.Identity.RequestOtp;

public sealed record RequestOtpResponse(DateTimeOffset ExpiresAtUtc, int ResendCooldownSeconds);
