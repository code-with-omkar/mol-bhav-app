using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Ingestion.Models;

namespace MolBhav.Application.Features.Ingestion.Admin.GetAdminIngestionJobErrors;

public sealed record GetAdminIngestionJobErrorsQuery(Guid JobId, int Page, int PageSize) : IQuery<PagedResult<AdminIngestionErrorResponse>>;
