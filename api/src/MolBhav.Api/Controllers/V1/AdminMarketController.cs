using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Market;
using MolBhav.Api.Setup;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Market.Admin.AddDistrict;
using MolBhav.Application.Features.Market.Admin.CreateMandi;
using MolBhav.Application.Features.Market.Admin.CreateState;
using MolBhav.Application.Features.Market.Admin.CreateSupplier;
using MolBhav.Application.Features.Market.Admin.GetAdminMandis;
using MolBhav.Application.Features.Market.Admin.GetAdminStates;
using MolBhav.Application.Features.Market.Admin.GetAdminSuppliers;
using MolBhav.Application.Features.Market.Admin.UpdateDistrict;
using MolBhav.Application.Features.Market.Admin.UpdateMandi;
using MolBhav.Application.Features.Market.Admin.UpdateState;
using MolBhav.Application.Features.Market.Admin.UpdateSupplier;
using MolBhav.Application.Features.Market.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// Market/location administration (BRD §22): states, districts, mandis, suppliers/hubs. Admin role only.
/// Nothing is deleted — items are deactivated (<c>isActive: false</c>) because prices reference them. Codes are immutable.
/// </summary>
[EvictReferenceDataCache] // edits here change cached catalog / market / plan / translation responses
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/market")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminMarketController(ISender sender) : ApiControllerBase(sender)
{
    private const string StatesPath = "states";
    private const string MandisPath = "mandis";
    private const string SuppliersPath = "suppliers";

    // ------------------------------------------------------------------ states / districts

    /// <summary>Full state tree including inactive states/districts.</summary>
    [HttpGet(StatesPath)]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminStateResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetStates(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminStatesQuery(), cancellationToken));

    /// <response code="409">Name or code already used (<c>State.NameTaken</c>, <c>State.CodeTaken</c>).</response>
    [HttpPost(StatesPath)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateState([FromBody] CreateStateRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateStateCommand(request.Name ?? string.Empty, request.Code ?? string.Empty);
        return CreatedEnvelope(await Sender.Send(command, cancellationToken), CollectionLocation(StatesPath));
    }

    [HttpPut(StatesPath + "/{stateId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateState(Guid stateId, [FromBody] UpdateStateRequest request, CancellationToken cancellationToken)
    {
        var command = new UpdateStateCommand(stateId, request.Name ?? string.Empty, request.IsActive);
        return NoContentOrProblem(await Sender.Send(command, cancellationToken));
    }

    /// <response code="409">District name already used in this state (<c>District.NameTaken</c>).</response>
    [HttpPost(StatesPath + "/{stateId:guid}/districts")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> AddDistrict(Guid stateId, [FromBody] AddDistrictRequest request, CancellationToken cancellationToken)
    {
        var command = new AddDistrictCommand(stateId, request.Name ?? string.Empty);
        return CreatedEnvelope(await Sender.Send(command, cancellationToken), CollectionLocation(StatesPath));
    }

    [HttpPut(StatesPath + "/{stateId:guid}/districts/{districtId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateDistrict(
        Guid stateId,
        Guid districtId,
        [FromBody] UpdateDistrictRequest request,
        CancellationToken cancellationToken)
    {
        var command = new UpdateDistrictCommand(stateId, districtId, request.Name ?? string.Empty, request.IsActive);
        return NoContentOrProblem(await Sender.Send(command, cancellationToken));
    }

    // ------------------------------------------------------------------ mandis

    [HttpGet(MandisPath)]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminMandiResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetMandis(
        [FromQuery] Guid? districtId,
        [FromQuery] string? search,
        [FromQuery] bool? isActive,
        CancellationToken cancellationToken,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize) =>
        PagedEnvelope(await Sender.Send(new GetAdminMandisQuery(districtId, search, isActive, page, pageSize), cancellationToken));

    /// <response code="400">Invalid input, or unknown district (<c>District.NotFound</c>).</response>
    /// <response code="409">Code already used (<c>Mandi.CodeTaken</c>).</response>
    [HttpPost(MandisPath)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateMandi([FromBody] CreateMandiRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateMandiCommand(request.Code ?? string.Empty, request.DistrictId ?? Guid.Empty, request.Name ?? string.Empty);
        return CreatedEnvelope(await Sender.Send(command, cancellationToken), CollectionLocation(MandisPath));
    }

    [HttpPut(MandisPath + "/{mandiId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateMandi(Guid mandiId, [FromBody] UpdateMandiRequest request, CancellationToken cancellationToken)
    {
        var command = new UpdateMandiCommand(mandiId, request.DistrictId ?? Guid.Empty, request.Name ?? string.Empty, request.IsActive);
        return NoContentOrProblem(await Sender.Send(command, cancellationToken));
    }

    // ------------------------------------------------------------------ suppliers

    [HttpGet(SuppliersPath)]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminSupplierResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetSuppliers(
        [FromQuery] Guid? districtId,
        [FromQuery] string? search,
        [FromQuery] bool? isActive,
        CancellationToken cancellationToken,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize) =>
        PagedEnvelope(await Sender.Send(new GetAdminSuppliersQuery(districtId, search, isActive, page, pageSize), cancellationToken));

    /// <response code="400">Invalid input, or unknown district (<c>District.NotFound</c>).</response>
    /// <response code="409">Code already used (<c>Supplier.CodeTaken</c>).</response>
    [HttpPost(SuppliersPath)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateSupplier([FromBody] CreateSupplierRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateSupplierCommand(
            request.Code ?? string.Empty,
            request.DistrictId ?? Guid.Empty,
            request.Name ?? string.Empty,
            request.ContactPhone);

        return CreatedEnvelope(await Sender.Send(command, cancellationToken), CollectionLocation(SuppliersPath));
    }

    [HttpPut(SuppliersPath + "/{supplierId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateSupplier(Guid supplierId, [FromBody] UpdateSupplierRequest request, CancellationToken cancellationToken)
    {
        var command = new UpdateSupplierCommand(
            supplierId,
            request.DistrictId ?? Guid.Empty,
            request.Name ?? string.Empty,
            request.ContactPhone,
            request.IsActive);

        return NoContentOrProblem(await Sender.Send(command, cancellationToken));
    }

    private string CollectionLocation(string path) => $"{Request.PathBase}/api/v1/admin/market/{path}";
}
