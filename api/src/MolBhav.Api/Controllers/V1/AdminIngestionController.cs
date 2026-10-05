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
using MolBhav.Application.Features.Ingestion.Admin.BackfillIngestion;
using MolBhav.Application.Features.Ingestion.Admin.GetAdminIngestionJob;
using MolBhav.Application.Features.Ingestion.Admin.GetAdminIngestionJobErrors;
using MolBhav.Application.Features.Ingestion.Admin.GetAdminIngestionJobs;
using MolBhav.Application.Features.Ingestion.Admin.GetIngestionSchedules;
using MolBhav.Application.Features.Ingestion.Admin.ImportIngestionFile;
using MolBhav.Application.Features.Ingestion.Admin.RunCategoryIngestion;
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
    /// <summary>Runs the source now. <paramref name="asOfDate"/> (IST, <c>yyyy-MM-dd</c>) defaults to yesterday.</summary>
    /// <response code="404">Unknown price source (<c>PriceSource.NotFound</c>).</response>
    [HttpPost("sources/{sourceId:guid}/run")]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> RunJob(Guid sourceId, [FromQuery] DateOnly? asOfDate, CancellationToken cancellationToken)
    {
        var command = new RunIngestionJobCommand(sourceId, IngestionTriggerType.Manual, currentUser.GetRequiredUserId(), asOfDate);
        var result = await Sender.Send(command, cancellationToken);
        return CreatedEnvelope(result, $"{Request.PathBase}/api/v1/admin/ingestion/jobs");
    }

    /// <summary>Queues one run per date (oldest first) and returns at once; each day appears as a job when it finishes.</summary>
    /// <response code="202">Queued.</response>
    /// <response code="404">Unknown price source (<c>PriceSource.NotFound</c>).</response>
    /// <response code="409">Too many backfills already waiting (<c>Ingestion.BackfillBusy</c>).</response>
    [HttpPost("sources/{sourceId:guid}/backfill")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<BackfillQueuedResponse>>(StatusCodes.Status202Accepted)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Backfill(Guid sourceId, [FromBody] BackfillIngestionRequest request, CancellationToken cancellationToken)
    {
        var result = await Sender.Send(
            new BackfillIngestionCommand(sourceId, request.FromDate, request.ToDate, currentUser.GetRequiredUserId()),
            cancellationToken);
        return result.IsSuccess ? Accepted(ApiResponse.Ok(result.Value)) : ToProblem(result.Error);
    }

    /// <summary>
    /// "Run all" for a procurement category: queues every active source of the category for one market day and returns
    /// at once; each source's run appears as a job when it finishes.
    /// </summary>
    /// <response code="202">Queued.</response>
    /// <response code="400">Future date, or the category has no active sources (<c>Ingestion.NoActiveSources</c>).</response>
    /// <response code="404">Unknown or inactive category (<c>Category.NotFound</c>).</response>
    /// <response code="409">Too many runs already waiting (<c>Ingestion.BackfillBusy</c>).</response>
    [HttpPost("categories/{categoryCode}/run")]
    [ProducesResponseType<ApiResponse<CategoryRunQueuedResponse>>(StatusCodes.Status202Accepted)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> RunCategory(string categoryCode, [FromQuery] DateOnly? asOfDate, CancellationToken cancellationToken)
    {
        var result = await Sender.Send(
            new RunCategoryIngestionCommand(categoryCode, currentUser.GetRequiredUserId(), asOfDate),
            cancellationToken);
        return result.IsSuccess ? Accepted(ApiResponse.Ok(result.Value)) : ToProblem(result.Error);
    }

    /// <summary>
    /// Imports a price CSV — the fallback when a source's API is down, and the only feed for sources without one. Accepts
    /// the MolBhav standard template (any category: <c>product_code, variant_code, location_kind, location_code,
    /// min_price, max_price, modal_price, arrival_qty, record_date</c>) or the source's own export where a parser exists
    /// (Agmarknet: data.gov.in export / portal report). Products outside the source's category are rejected per row.
    /// Creates one job (trigger <c>Upload</c>) and returns its id; check it like any run (counts + row errors).
    /// </summary>
    /// <response code="201">Imported; the job holds the counts.</response>
    /// <response code="400">Not a CSV, too large, or no recognisable header (<c>Ingestion.FileUnreadable</c>).</response>
    /// <response code="404">Unknown price source (<c>PriceSource.NotFound</c>).</response>
    [HttpPost("sources/{sourceId:guid}/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(UploadRequestLimitBytes)]
    [RequestFormLimits(MultipartBodyLengthLimit = UploadRequestLimitBytes)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Upload(Guid sourceId, IFormFile file, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(file);
        await using var content = file.OpenReadStream();
        var command = new ImportIngestionFileCommand(sourceId, currentUser.GetRequiredUserId(), file.FileName, file.Length, content);
        return CreatedEnvelope(await Sender.Send(command, cancellationToken), $"{Request.PathBase}/api/v1/admin/ingestion/jobs");
    }

    /// <summary>10 MB file (the command's limit) plus multipart overhead.</summary>
    private const long UploadRequestLimitBytes = 11 * 1024 * 1024;

    /// <summary>Every price source with its category, schedule (IST), next run and most recent job — grouped by category.</summary>
    /// <param name="category">Optional procurement category code (e.g. <c>construction</c>) to list only its sources.</param>
    /// <param name="cancellationToken">Request cancellation.</param>
    [HttpGet("schedules")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminIngestionScheduleResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetSchedules([FromQuery] string? category, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetIngestionSchedulesQuery(category), cancellationToken));

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
