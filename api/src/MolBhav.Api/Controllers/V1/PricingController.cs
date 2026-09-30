using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Pricing.GetLatestByLocation;
using MolBhav.Application.Features.Pricing.GetLatestPrices;
using MolBhav.Application.Features.Pricing.GetPriceHistory;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Pricing;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Price comparison and trend screens (BRD §10/§11/§12). Requires a signed-in user (fallback auth policy).</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/pricing")]
public sealed class PricingController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>Comparison matrix: latest non-voided price per mandi/supplier for a product.</summary>
    [HttpGet("latest")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<LatestPriceResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetLatestPrices(
        [FromQuery] Guid productId,
        [FromQuery] LocationKind? locationKind,
        [FromQuery] Guid? districtId,
        CancellationToken cancellationToken,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize) =>
        PagedEnvelope(await Sender.Send(new GetLatestPricesQuery(productId, locationKind, districtId, page, pageSize), cancellationToken));

    /// <summary>Browse by mandi: latest non-voided price per product/variant at one location (last 30 days).</summary>
    [HttpGet("latest-by-location")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<LocationLatestPriceResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetLatestByLocation(
        [FromQuery] LocationKind locationKind,
        [FromQuery] Guid locationId,
        CancellationToken cancellationToken,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize) =>
        PagedEnvelope(await Sender.Send(new GetLatestByLocationQuery(locationKind, locationId, page, pageSize), cancellationToken));

    /// <summary>Trend sparkline: non-voided prices for a product at one location over a date range.</summary>
    [HttpGet("history")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<PriceHistoryPointResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetPriceHistory(
        [FromQuery] Guid productId,
        [FromQuery] LocationKind locationKind,
        [FromQuery] Guid locationId,
        [FromQuery] DateOnly fromDate,
        [FromQuery] DateOnly toDate,
        CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetPriceHistoryQuery(productId, locationKind, locationId, fromDate, toDate), cancellationToken));
}
