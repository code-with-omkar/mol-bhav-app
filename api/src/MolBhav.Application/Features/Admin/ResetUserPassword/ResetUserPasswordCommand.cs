using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Admin.ResetUserPassword;

/// <summary>The temporary password shown to the admin once; it is never stored in plain text or in the audit log.</summary>
public sealed record ResetUserPasswordResponse(string TemporaryPassword);

/// <summary>Gives a user a new random password. An admin cannot reset their own or another admin's account.</summary>
public sealed record ResetUserPasswordCommand(Guid UserId, Guid ActingUserId)
    : ICommand<ResetUserPasswordResponse>, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "User.ResetPassword";

    string? IAuditedCommand.AuditTarget => UserId.ToString();

    string IAuditedCommand.AuditSummary => "Reset a user's password";
}
