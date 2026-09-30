using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Reporting.Models;
using MolBhav.Domain.Reporting;

namespace MolBhav.Application.Features.Reporting.Admin.GetAdminReports;

public sealed record GetAdminReportsQuery(
    Guid? UserId,
    ReportType? ReportType,
    ReportStatus? Status,
    int Page,
    int PageSize) : IQuery<PagedResult<AdminReportResponse>>;
