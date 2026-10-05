using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Pricing;
using MolBhav.Api.Setup;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Pricing.Admin.CreatePriceSource;
using MolBhav.Application.Features.Pricing.Admin.GetAdminPriceRecords;
using MolBhav.Application.Features.Pricing.Admin.GetAdminPriceSources;
using MolBhav.Application.Features.Pricing.Admin.RecordPrice;
using MolBhav.Application.Features.Pricing.Admin.UpdatePriceSource;
using MolBhav.Application.Features.Pricing.Admin.VoidPriceRecord;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Pricing;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// Pricing administration (BRD §19/§22): price sources and manual price entry — the same validation path the
/// future Ingestion module will call into. Admin role only. Records are voided, never deleted, to keep history intact.
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/pricing")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminPricingController(ISender sender) : ApiControllerBase(sender)
{
    private const string SourcesPath = "sources";
    private const string RecordsPath = "records";

    [HttpGet(SourcesPath)]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminPriceSourceResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSources(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminPriceSourcesQuery(), cancellationToken));

    /// <response code="409">Code already used (<c>PriceSource.CodeTaken</c>).</response>
    /// <response code="400">Invalid input or unknown category (<c>PriceSource.CategoryNotFound</c>).</response>
    [HttpPost(SourcesPath)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateSource([FromBody] CreatePriceSourceRequest request, CancellationToken cancellationToken)
    {
        var command = new CreatePriceSourceCommand(request.Code ?? string.Empty, request.Name ?? string.Empty, request.CategoryCode ?? string.Empty);
        return CreatedEnvelope(await Sender.Send(command, cancellationToken), CollectionLocation(SourcesPath));
    }

    [HttpPut(SourcesPath + "/{priceSourceId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateSource(Guid priceSourceId, [FromBody] UpdatePriceSourceRequest request, CancellationToken cancellationToken)
    {
        var command = new UpdatePriceSourceCommand(priceSourceId, request.Name ?? string.Empty, request.IsActive, request.CategoryCode ?? string.Empty);
        return NoContentOrProblem(await Sender.Send(command, cancellationToken));
    }

    [HttpGet(RecordsPath)]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminPriceRecordResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetRecords(
        [FromQuery] Guid? productId,
        [FromQuery] LocationKind? locationKind,
        [FromQuery] Guid? locationId,
        [FromQuery] DateOnly? fromDate,
        [FromQuery] DateOnly? toDate,
        [FromQuery] bool? isVoided,
        CancellationToken cancellationToken,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize) =>
        PagedEnvelope(await Sender.Send(
            new GetAdminPriceRecordsQuery(productId, locationKind, locationId, fromDate, toDate, isVoided, page, pageSize),
            cancellationToken));

    /// <response code="400">Invalid input, or an unknown product/variant/unit/mandi/supplier/source reference.</response>
    /// <response code="409">A record already exists for this product/location/source/date (<c>PriceRecord.Duplicate</c>).</response>
    [HttpPost(RecordsPath)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> RecordPrice([FromBody] RecordPriceRequest request, CancellationToken cancellationToken)
    {
        var command = new RecordPriceCommand(
            request.ProductId ?? Guid.Empty,
            request.VariantId,
            request.UnitId ?? Guid.Empty,
            request.LocationKind,
            request.MandiId,
            request.SupplierId,
            request.PriceSourceId ?? Guid.Empty,
            request.MinPrice,
            request.MaxPrice,
            request.ModalPrice ?? -1m,
            request.ArrivalQuantity,
            request.RecordDate ?? default);

        return CreatedEnvelope(await Sender.Send(command, cancellationToken), CollectionLocation(RecordsPath));
    }

    [HttpPost(RecordsPath + "/{priceRecordId:guid}/void")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> VoidRecord(Guid priceRecordId, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new VoidPriceRecordCommand(priceRecordId), cancellationToken));

    private string CollectionLocation(string path) => $"{Request.PathBase}/api/v1/admin/pricing/{path}";
}
