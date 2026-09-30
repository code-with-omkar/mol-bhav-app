using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Reporting;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Reporting.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Reporting.Admin.GetAdminReports;

internal sealed class GetAdminReportsQueryHandler(IReportReadService readService)
    : IQueryHandler<GetAdminReportsQuery, PagedResult<AdminReportResponse>>
{
    public async Task<Result<PagedResult<AdminReportResponse>>> Handle(GetAdminReportsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminReportsAsync(
            new AdminReportFilter(request.UserId, request.ReportType, request.Status, new PageRequest(request.Page, request.PageSize)),
            cancellationToken));
}
