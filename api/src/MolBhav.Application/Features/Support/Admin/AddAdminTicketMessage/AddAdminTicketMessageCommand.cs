using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Support.Admin.AddAdminTicketMessage;

public sealed record AddAdminTicketMessageCommand(Guid TicketId, string? Message) : ICommand, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Support.Reply";

    string? IAuditedCommand.AuditTarget => TicketId.ToString();

    // The reply text is the user's private conversation: it is not copied into the log.
    string IAuditedCommand.AuditSummary => "Replied to a support ticket";
}
