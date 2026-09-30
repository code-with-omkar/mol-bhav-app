using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.GetCategories;
using MolBhav.Application.Features.Catalog.GetProduct;
using MolBhav.Application.Features.Catalog.GetProducts;
using MolBhav.Application.Features.Catalog.GetUnits;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// Catalog for the mobile screens (BRD §6). Names come back in the <c>Accept-Language</c> language, falling back to
/// the default language and then English. Only active items are returned.
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/catalog")]
[AllowAnonymous]
public sealed class CatalogController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>Select Category screen: categories with their sub-categories.</summary>
    [HttpGet("categories")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<CategoryResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCategories(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetCategoriesQuery(), cancellationToken));

    /// <summary>Products in a category, optionally one sub-category and/or a name search (matches any language).</summary>
    /// <param name="categoryCode">e.g. <c>agriculture</c>.</param>
    /// <param name="subCategoryId">Optional sub-category filter.</param>
    /// <param name="search">Optional name/code search, 60 chars max.</param>
    /// <param name="page">1-based.</param>
    /// <param name="pageSize">1–100, default 20.</param>
    /// <param name="cancellationToken">Request abort.</param>
    /// <response code="404">Unknown or inactive category (<c>ProcurementCategory.NotFound</c>).</response>
    [HttpGet("categories/{categoryCode}/products")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<ProductSummaryResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetProducts(
        string categoryCode,
        [FromQuery] Guid? subCategoryId,
        [FromQuery] string? search,
        CancellationToken cancellationToken,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize) =>
        PagedEnvelope(await Sender.Send(new GetProductsQuery(categoryCode, subCategoryId, search, page, pageSize), cancellationToken));

    /// <summary>Product header for the comparison / trends / opportunity screens: names, default unit, variants.</summary>
    /// <response code="404">Unknown or inactive product (<c>Product.NotFound</c>).</response>
    [HttpGet("products/{productId:guid}")]
    [ProducesResponseType<ApiResponse<ProductDetailResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetProduct(Guid productId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetProductQuery(productId), cancellationToken));

    /// <summary>Units with conversion factors to their dimension's base unit (quantity pickers, client-side conversion).</summary>
    [HttpGet("units")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<UnitResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetUnits(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetUnitsQuery(), cancellationToken));
}
