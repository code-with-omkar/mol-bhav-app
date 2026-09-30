using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Support;

namespace MolBhav.Application.Features.Support.Admin.UpdateTicketStatus;

public sealed record UpdateTicketStatusCommand(Guid TicketId, SupportTicketStatus? Status) : ICommand;
