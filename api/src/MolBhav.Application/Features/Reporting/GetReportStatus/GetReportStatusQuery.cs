using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Reporting.Models;

namespace MolBhav.Application.Features.Reporting.GetReportStatus;

public sealed record GetReportStatusQuery(Guid ReportId) : IQuery<ReportResponse>;
