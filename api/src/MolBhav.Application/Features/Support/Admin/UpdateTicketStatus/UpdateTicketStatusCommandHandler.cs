using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Support;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Support.Admin.UpdateTicketStatus;

internal sealed class UpdateTicketStatusCommandHandler(
    ISupportTicketRepository tickets,
    TimeProvider timeProvider) : ICommandHandler<UpdateTicketStatusCommand>
{
    public async Task<Result> Handle(UpdateTicketStatusCommand request, CancellationToken cancellationToken)
    {
        var ticket = await tickets.GetByIdAsync(request.TicketId, cancellationToken);
        if (ticket is null)
        {
            return Error.NotFound("SupportTicket.NotFound", "Ticket not found.");
        }

        return ticket.ChangeStatus(request.Status!.Value, timeProvider.GetUtcNow());
    }
}
