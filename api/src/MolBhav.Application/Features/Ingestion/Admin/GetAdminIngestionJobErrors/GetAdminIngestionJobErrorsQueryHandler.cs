using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Ingestion.Admin.GetAdminIngestionJobErrors;

internal sealed class GetAdminIngestionJobErrorsQueryHandler(IIngestionReadService readService)
    : IQueryHandler<GetAdminIngestionJobErrorsQuery, PagedResult<AdminIngestionErrorResponse>>
{
    public async Task<Result<PagedResult<AdminIngestionErrorResponse>>> Handle(GetAdminIngestionJobErrorsQuery request, CancellationToken cancellationToken)
    {
        if (await readService.GetAdminJobAsync(request.JobId, cancellationToken) is null)
        {
            return Error.NotFound("DataIngestionJob.NotFound", "Ingestion job not found.");
        }

        return await readService.GetAdminJobErrorsAsync(request.JobId, new PageRequest(request.Page, request.PageSize), cancellationToken);
    }
}
