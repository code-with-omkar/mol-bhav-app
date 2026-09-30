using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Market.GetDistricts;
using MolBhav.Application.Features.Market.GetMandis;
using MolBhav.Application.Features.Market.GetStates;
using MolBhav.Application.Features.Market.GetSuppliers;
using MolBhav.Application.Features.Market.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Location/market pickers for comparison and watchlist screens (BRD §11/§12). Only active items are returned.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/market")]
[AllowAnonymous]
public sealed class MarketController(ISender sender) : ApiControllerBase(sender)
{
    [HttpGet("states")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<StateResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetStates(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetStatesQuery(), cancellationToken));

    /// <response code="404">Unknown or inactive state (<c>State.NotFound</c>).</response>
    [HttpGet("states/{stateId:guid}/districts")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<DistrictResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetDistricts(Guid stateId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetDistrictsQuery(stateId), cancellationToken));

    /// <summary>Agriculture pricing locations (BRD §11), optionally narrowed to a district and/or a name search.</summary>
    [HttpGet("mandis")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<MandiResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetMandis(
        [FromQuery] Guid? districtId,
        [FromQuery] string? search,
        CancellationToken cancellationToken,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize) =>
        PagedEnvelope(await Sender.Send(new GetMandisQuery(districtId, search, page, pageSize), cancellationToken));

    /// <summary>Construction regional suppliers/hubs (BRD §12), optionally narrowed to a district and/or a name search.</summary>
    [HttpGet("suppliers")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<SupplierResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetSuppliers(
        [FromQuery] Guid? districtId,
        [FromQuery] string? search,
        CancellationToken cancellationToken,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize) =>
        PagedEnvelope(await Sender.Send(new GetSuppliersQuery(districtId, search, page, pageSize), cancellationToken));
}
