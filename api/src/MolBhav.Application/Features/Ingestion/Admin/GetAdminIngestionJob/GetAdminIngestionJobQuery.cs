using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Ingestion.Models;

namespace MolBhav.Application.Features.Ingestion.Admin.GetAdminIngestionJob;

public sealed record GetAdminIngestionJobQuery(Guid JobId) : IQuery<AdminIngestionJobResponse>;
