using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Reporting;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Reporting.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Reporting.GetMyReports;

internal sealed class GetMyReportsQueryHandler(IReportReadService readService, ICurrentUser currentUser)
    : IQueryHandler<GetMyReportsQuery, PagedResult<ReportResponse>>
{
    public async Task<Result<PagedResult<ReportResponse>>> Handle(GetMyReportsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetMyReportsAsync(currentUser.GetRequiredUserId(), new PageRequest(request.Page, request.PageSize), cancellationToken));
}
