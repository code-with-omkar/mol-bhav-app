using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Support;
using MolBhav.Application.Features.Support.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Support.Admin.GetAdminTicket;

internal sealed class GetAdminTicketQueryHandler(ISupportReadService readService)
    : IQueryHandler<GetAdminTicketQuery, SupportTicketResponse>
{
    public async Task<Result<SupportTicketResponse>> Handle(GetAdminTicketQuery request, CancellationToken cancellationToken)
    {
        // No owner filter: support reads any ticket.
        var ticket = await readService.GetTicketAsync(request.TicketId, userId: null, cancellationToken);
        return ticket is null ? Error.NotFound("SupportTicket.NotFound", "Ticket not found.") : ticket;
    }
}
