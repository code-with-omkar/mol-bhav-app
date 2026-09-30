using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Setup;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Reporting.Admin.GetAdminReports;
using MolBhav.Application.Features.Reporting.Models;
using MolBhav.Domain.Reporting;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Read-only report-generation monitoring (BRD §25). Admin role only.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/reports")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminReportsController(ISender sender) : ApiControllerBase(sender)
{
    [HttpGet]
    [ProducesResponseType<ApiResponse<PagedResult<AdminReportResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetReports(
        [FromQuery] Guid? userId,
        [FromQuery] ReportType? reportType,
        [FromQuery] ReportStatus? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize,
        CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetAdminReportsQuery(userId, reportType, status, page, pageSize), cancellationToken));
}
