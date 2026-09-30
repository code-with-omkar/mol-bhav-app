using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Ingestion.Admin.GetAdminIngestionJobs;

internal sealed class GetAdminIngestionJobsQueryHandler(IIngestionReadService readService)
    : IQueryHandler<GetAdminIngestionJobsQuery, PagedResult<AdminIngestionJobResponse>>
{
    public async Task<Result<PagedResult<AdminIngestionJobResponse>>> Handle(GetAdminIngestionJobsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminJobsAsync(
            new AdminIngestionJobFilter(request.PriceSourceId, request.Status, new PageRequest(request.Page, request.PageSize)),
            cancellationToken));
}
