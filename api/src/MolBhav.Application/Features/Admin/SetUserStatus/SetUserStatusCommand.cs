using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Admin.Models;

namespace MolBhav.Application.Features.Admin.SetUserStatus;

/// <summary>Suspends or reinstates an account. An admin cannot act on their own account.</summary>
public sealed record SetUserStatusCommand(Guid UserId, UserStatusAction Action, Guid ActingUserId) : ICommand, IAuditedCommand
{
    string IAuditedCommand.AuditAction => Action == UserStatusAction.Suspend ? "User.Suspend" : "User.Reinstate";

    string? IAuditedCommand.AuditTarget => UserId.ToString();

    string IAuditedCommand.AuditSummary =>
        Action == UserStatusAction.Suspend ? "Suspended a user account" : "Reinstated a user account";
}
