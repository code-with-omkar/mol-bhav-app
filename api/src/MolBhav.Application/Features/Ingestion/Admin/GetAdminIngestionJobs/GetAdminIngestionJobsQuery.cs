using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Ingestion.Admin.GetAdminIngestionJobs;

public sealed record GetAdminIngestionJobsQuery(Guid? PriceSourceId, IngestionJobStatus? Status, int Page, int PageSize)
    : IQuery<PagedResult<AdminIngestionJobResponse>>;
