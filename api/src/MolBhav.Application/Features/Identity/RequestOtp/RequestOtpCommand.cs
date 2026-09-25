using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.RequestOtp;

/// <summary>Login screen — "send code" (BRD §7). Anonymous; rate-limited separately at the API layer (<c>RateLimitPolicies.Otp</c>).</summary>
public sealed record RequestOtpCommand(string PhoneNumber) : ICommand<RequestOtpResponse>;
