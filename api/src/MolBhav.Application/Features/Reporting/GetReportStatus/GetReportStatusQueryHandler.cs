using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Reporting;
using MolBhav.Application.Features.Reporting.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Reporting.GetReportStatus;

internal sealed class GetReportStatusQueryHandler(IReportReadService readService, ICurrentUser currentUser)
    : IQueryHandler<GetReportStatusQuery, ReportResponse>
{
    public async Task<Result<ReportResponse>> Handle(GetReportStatusQuery request, CancellationToken cancellationToken)
    {
        var report = await readService.GetReportAsync(request.ReportId, currentUser.GetRequiredUserId(), cancellationToken);
        return report is null ? Error.NotFound("Report.NotFound", "Report not found.") : report;
    }
}
