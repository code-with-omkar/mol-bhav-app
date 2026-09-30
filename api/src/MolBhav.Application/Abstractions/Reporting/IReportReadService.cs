using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Reporting.Models;
using MolBhav.Domain.Reporting;

namespace MolBhav.Application.Abstractions.Reporting;

/// <summary>Dapper-backed reads for the signed-in user's reports and the admin monitoring list.</summary>
public interface IReportReadService
{
    Task<PagedResult<ReportResponse>> GetMyReportsAsync(Guid userId, PageRequest page, CancellationToken cancellationToken = default);

    /// <summary>Null when the report doesn't exist or belongs to someone else.</summary>
    Task<ReportResponse?> GetReportAsync(Guid reportId, Guid userId, CancellationToken cancellationToken = default);

    Task<PagedResult<AdminReportResponse>> GetAdminReportsAsync(AdminReportFilter filter, CancellationToken cancellationToken = default);
}

public sealed record AdminReportFilter(Guid? UserId, ReportType? ReportType, ReportStatus? Status, PageRequest Page);
