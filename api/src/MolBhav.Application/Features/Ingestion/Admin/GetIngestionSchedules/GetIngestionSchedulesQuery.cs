using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Ingestion.Models;

namespace MolBhav.Application.Features.Ingestion.Admin.GetIngestionSchedules;

public sealed record GetIngestionSchedulesQuery : IQuery<IReadOnlyList<AdminIngestionScheduleResponse>>;
