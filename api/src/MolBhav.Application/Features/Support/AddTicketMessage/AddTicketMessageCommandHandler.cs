using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Support;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Support.AddTicketMessage;

internal sealed class AddTicketMessageCommandHandler(
    ISupportTicketRepository tickets,
    ICurrentUser currentUser,
    TimeProvider timeProvider) : ICommandHandler<AddTicketMessageCommand>
{
    public async Task<Result> Handle(AddTicketMessageCommand request, CancellationToken cancellationToken)
    {
        var ticket = await tickets.GetByIdAsync(request.TicketId, cancellationToken);
        if (ticket is null || ticket.UserId != currentUser.GetRequiredUserId())
        {
            // Same 404 whether it's someone else's ticket or doesn't exist — never reveal other users' data.
            return Error.NotFound("SupportTicket.NotFound", "Ticket not found.");
        }

        return ticket.AddUserMessage(request.Message, timeProvider.GetUtcNow());
    }
}
