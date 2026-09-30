using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Support.AddTicketMessage;

public sealed record AddTicketMessageCommand(Guid TicketId, string? Message) : ICommand;
