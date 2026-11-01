using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Audit.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Audit.GetAuditEntries;

internal sealed class GetAuditEntriesQueryHandler(IAuditReadService readService)
    : IQueryHandler<GetAuditEntriesQuery, PagedResult<AuditEntryResponse>>
{
    public async Task<Result<PagedResult<AuditEntryResponse>>> Handle(GetAuditEntriesQuery request, CancellationToken cancellationToken)
    {
        var action = string.IsNullOrWhiteSpace(request.Action) ? null : request.Action.Trim();
        return Result.Success(await readService.GetEntriesAsync(action, new PageRequest(request.Page, request.PageSize), cancellationToken));
    }
}
