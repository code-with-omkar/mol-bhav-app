using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Support;

namespace MolBhav.Application.Features.Support.Admin.UpdateTicketStatus;

public sealed record UpdateTicketStatusCommand(Guid TicketId, SupportTicketStatus? Status) : ICommand, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Support.SetStatus";

    string? IAuditedCommand.AuditTarget => TicketId.ToString();

    string IAuditedCommand.AuditSummary => $"Set a support ticket to {Status}";
}
