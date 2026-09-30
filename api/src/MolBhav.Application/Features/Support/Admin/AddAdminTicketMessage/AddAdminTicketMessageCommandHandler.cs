using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Support;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Support.Admin.AddAdminTicketMessage;

/// <summary>
/// Support's reply. The aggregate raises <c>SupportTicketRepliedDomainEvent</c>, which goes to the outbox in this
/// same transaction and reaches the Notification module through the <c>OutboxProcessor</c>.
/// </summary>
internal sealed class AddAdminTicketMessageCommandHandler(
    ISupportTicketRepository tickets,
    ICurrentUser currentUser,
    TimeProvider timeProvider) : ICommandHandler<AddAdminTicketMessageCommand>
{
    public async Task<Result> Handle(AddAdminTicketMessageCommand request, CancellationToken cancellationToken)
    {
        var ticket = await tickets.GetByIdAsync(request.TicketId, cancellationToken);
        if (ticket is null)
        {
            return Error.NotFound("SupportTicket.NotFound", "Ticket not found.");
        }

        return ticket.AddAdminMessage(currentUser.GetRequiredUserId(), request.Message, timeProvider.GetUtcNow());
    }
}
