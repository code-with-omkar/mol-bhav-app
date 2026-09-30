using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Support;
using MolBhav.Application.Features.Support.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Support.GetTicket;

internal sealed class GetTicketQueryHandler(ISupportReadService readService, ICurrentUser currentUser)
    : IQueryHandler<GetTicketQuery, SupportTicketResponse>
{
    public async Task<Result<SupportTicketResponse>> Handle(GetTicketQuery request, CancellationToken cancellationToken)
    {
        // Owner-scoped read: someone else's ticket id behaves exactly as an unknown one.
        var ticket = await readService.GetTicketAsync(request.TicketId, currentUser.GetRequiredUserId(), cancellationToken);
        return ticket is null ? Error.NotFound("SupportTicket.NotFound", "Ticket not found.") : ticket;
    }
}
