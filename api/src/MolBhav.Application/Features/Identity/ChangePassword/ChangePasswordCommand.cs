using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.ChangePassword;

/// <summary>
/// More → Change password. A user who has a password must give the current one; a user who signs in another way
/// (Google, OTP) and has none can set their first password without it.
/// </summary>
public sealed record ChangePasswordCommand(string? CurrentPassword, string NewPassword) : ICommand;
