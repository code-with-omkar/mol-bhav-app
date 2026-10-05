using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Ingestion.Models;

namespace MolBhav.Application.Features.Ingestion.Admin.GetIngestionSchedules;

/// <param name="CategoryCode">Only sources of this procurement category; null = all categories.</param>
public sealed record GetIngestionSchedulesQuery(string? CategoryCode = null) : IQuery<IReadOnlyList<AdminIngestionScheduleResponse>>;
