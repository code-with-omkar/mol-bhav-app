using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Abstractions.Ingestion;

/// <summary>Dapper-backed admin reads for ingestion monitoring (BRD §22: "Monitor ingestion jobs and failures").</summary>
public interface IIngestionReadService
{
    Task<PagedResult<AdminIngestionJobResponse>> GetAdminJobsAsync(AdminIngestionJobFilter filter, CancellationToken cancellationToken = default);

    /// <summary>Null when the job does not exist.</summary>
    Task<AdminIngestionJobResponse?> GetAdminJobAsync(Guid jobId, CancellationToken cancellationToken = default);

    Task<PagedResult<AdminIngestionErrorResponse>> GetAdminJobErrorsAsync(Guid jobId, PageRequest page, CancellationToken cancellationToken = default);
}

public sealed record AdminIngestionJobFilter(Guid? PriceSourceId, IngestionJobStatus? Status, PageRequest Page);
