using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Ingestion.Admin.GetAdminIngestionJob;

internal sealed class GetAdminIngestionJobQueryHandler(IIngestionReadService readService)
    : IQueryHandler<GetAdminIngestionJobQuery, AdminIngestionJobResponse>
{
    public async Task<Result<AdminIngestionJobResponse>> Handle(GetAdminIngestionJobQuery request, CancellationToken cancellationToken)
    {
        var job = await readService.GetAdminJobAsync(request.JobId, cancellationToken);
        return job is null ? Error.NotFound("DataIngestionJob.NotFound", "Ingestion job not found.") : job;
    }
}
