using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.VerifyOtp;

/// <summary>Login screen — "enter code". Anonymous. Registers the account just-in-time on first success (BRD §7).</summary>
public sealed record VerifyOtpCommand(string PhoneNumber, string Code) : ICommand<VerifyOtpResponse>;
