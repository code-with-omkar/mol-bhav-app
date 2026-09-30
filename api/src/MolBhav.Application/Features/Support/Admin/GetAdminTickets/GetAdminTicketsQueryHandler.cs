using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Support;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Support.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Support.Admin.GetAdminTickets;

internal sealed class GetAdminTicketsQueryHandler(ISupportReadService readService)
    : IQueryHandler<GetAdminTicketsQuery, PagedResult<AdminSupportTicketResponse>>
{
    public async Task<Result<PagedResult<AdminSupportTicketResponse>>> Handle(GetAdminTicketsQuery request, CancellationToken cancellationToken)
    {
        var filter = new AdminSupportTicketFilter(
            request.Status,
            request.Category,
            request.Search,
            new PageRequest(request.Page, request.PageSize));

        return Result.Success(await readService.GetAdminTicketsAsync(filter, cancellationToken));
    }
}
