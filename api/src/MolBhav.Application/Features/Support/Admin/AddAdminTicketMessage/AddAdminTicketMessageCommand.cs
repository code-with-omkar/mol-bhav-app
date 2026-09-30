using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Support.Admin.AddAdminTicketMessage;

public sealed record AddAdminTicketMessageCommand(Guid TicketId, string? Message) : ICommand;
