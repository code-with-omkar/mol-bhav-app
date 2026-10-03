using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.RegisterWithPassword;

/// <summary>
/// "Create account" — mobile number + password, no SMS. Anonymous. Logs the new user straight in.
/// The number is not verified on this path; turn OTP back on (<c>ILoginMethods.OtpEnabled</c>) to prove ownership.
/// </summary>
public sealed record RegisterWithPasswordCommand(string PhoneNumber, string Password) : ICommand<LoginSessionResponse>;
