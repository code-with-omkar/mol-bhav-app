using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Ingestion;
using MolBhav.Api.Setup;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Ingestion.Admin.GetAdminIngestionJob;
using MolBhav.Application.Features.Ingestion.Admin.GetAdminIngestionJobErrors;
using MolBhav.Application.Features.Ingestion.Admin.GetAdminIngestionJobs;
using MolBhav.Application.Features.Ingestion.Admin.GetIngestionSchedules;
using MolBhav.Application.Features.Ingestion.Admin.UpdateIngestionSchedule;
using MolBhav.Application.Features.Ingestion.Admin.RunIngestionJob;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Ingestion job monitoring and manual triggering (BRD §9/§22: "Monitor ingestion jobs and failures"). Admin role only.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/ingestion")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminIngestionController(ISender sender, ICurrentUser currentUser) : ApiControllerBase(sender)
{
    /// <response code="404">Unknown price source (<c>PriceSource.NotFound</c>).</response>
    [HttpPost("sources/{sourceId:guid}/run")]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> RunJob(Guid sourceId, CancellationToken cancellationToken)
    {
        var command = new RunIngestionJobCommand(sourceId, IngestionTriggerType.Manual, currentUser.GetRequiredUserId());
        var result = await Sender.Send(command, cancellationToken);
        return CreatedEnvelope(result, $"{Request.PathBase}/api/v1/admin/ingestion/jobs");
    }

    /// <summary>Every price source with its schedule (IST), next run and most recent job.</summary>
    [HttpGet("schedules")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminIngestionScheduleResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSchedules(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetIngestionSchedulesQuery(), cancellationToken));

    /// <summary>Creates or replaces the source's schedule; the next run is recomputed immediately.</summary>
    /// <response code="404">Unknown price source (<c>PriceSource.NotFound</c>).</response>
    [HttpPut("sources/{sourceId:guid}/schedule")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateSchedule(Guid sourceId, [FromBody] UpdateIngestionScheduleRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(
            new UpdateIngestionScheduleCommand(sourceId, request.IsEnabled, request.Frequency, request.TimeOfDay, request.DayOfWeek, request.IntervalHours),
            cancellationToken));

    [HttpGet("jobs")]
    [ProducesResponseType<ApiResponse<PagedResult<AdminIngestionJobResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetJobs(
        [FromQuery] Guid? priceSourceId,
        [FromQuery] IngestionJobStatus? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize,
        CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetAdminIngestionJobsQuery(priceSourceId, status, page, pageSize), cancellationToken));

    /// <response code="404">Unknown job (<c>DataIngestionJob.NotFound</c>).</response>
    [HttpGet("jobs/{jobId:guid}")]
    [ProducesResponseType<ApiResponse<AdminIngestionJobResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetJob(Guid jobId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminIngestionJobQuery(jobId), cancellationToken));

    /// <response code="404">Unknown job (<c>DataIngestionJob.NotFound</c>).</response>
    [HttpGet("jobs/{jobId:guid}/errors")]
    [ProducesResponseType<ApiResponse<PagedResult<AdminIngestionErrorResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetJobErrors(
        Guid jobId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize,
        CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetAdminIngestionJobErrorsQuery(jobId, page, pageSize), cancellationToken));
}
