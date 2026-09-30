using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Reporting;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Reporting.DownloadReport;
using MolBhav.Application.Features.Reporting.GetMyReports;
using MolBhav.Application.Features.Reporting.GetReportStatus;
using MolBhav.Application.Features.Reporting.Models;
using MolBhav.Application.Features.Reporting.RequestReport;

namespace MolBhav.Api.Controllers.V1;

/// <summary>The signed-in user's report exports (BRD §25). Generation runs asynchronously behind the outbox —
/// poll <see cref="GetReportStatus"/> for completion. Requires a signed-in user (fallback auth policy).</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/reports")]
public sealed class ReportsController(ISender sender) : ApiControllerBase(sender)
{
    [HttpGet]
    [ProducesResponseType<ApiResponse<PagedResult<ReportResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyReports(
        [FromQuery] int page = 1, [FromQuery] int pageSize = PageRequest.DefaultPageSize, CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetMyReportsQuery(page, pageSize), cancellationToken));

    [HttpPost]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> RequestReport([FromBody] RequestReportRequest request, CancellationToken cancellationToken)
    {
        var command = new RequestReportCommand(request.ReportType, request.Format, request.Parameters);
        return CreatedEnvelope(await Sender.Send(command, cancellationToken), $"{Request.PathBase}/api/v1/reports");
    }

    [HttpGet("{reportId:guid}")]
    [ProducesResponseType<ApiResponse<ReportResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetReportStatus(Guid reportId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetReportStatusQuery(reportId), cancellationToken));

    /// <summary>The rendered file of a <c>Ready</c> report, owner only.</summary>
    /// <response code="409">Still pending or failed (<c>Report.NotReady</c>).</response>
    [HttpGet("{reportId:guid}/download")]
    [ProducesResponseType<FileContentResult>(StatusCodes.Status200OK, "application/pdf", "text/csv")]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Download(Guid reportId, CancellationToken cancellationToken)
    {
        var result = await Sender.Send(new DownloadReportCommand(reportId), cancellationToken);
        return result.IsSuccess
            ? File(result.Value.Content, result.Value.ContentType, result.Value.FileName)
            : ToProblem(result.Error);
    }
}
