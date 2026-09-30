using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Support;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Support.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Support.GetMyTickets;

internal sealed class GetMyTicketsQueryHandler(ISupportReadService readService, ICurrentUser currentUser)
    : IQueryHandler<GetMyTicketsQuery, PagedResult<SupportTicketSummaryResponse>>
{
    public async Task<Result<PagedResult<SupportTicketSummaryResponse>>> Handle(GetMyTicketsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetMyTicketsAsync(
            currentUser.GetRequiredUserId(), new PageRequest(request.Page, request.PageSize), cancellationToken));
}
