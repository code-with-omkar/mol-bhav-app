using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Catalog;
using MolBhav.Api.Setup;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Admin.AddSubCategory;
using MolBhav.Application.Features.Catalog.Admin.AddVariant;
using MolBhav.Application.Features.Catalog.Admin.CreateCategory;
using MolBhav.Application.Features.Catalog.Admin.CreateProduct;
using MolBhav.Application.Features.Catalog.Admin.CreateUnit;
using MolBhav.Application.Features.Catalog.Admin.GetAdminCategories;
using MolBhav.Application.Features.Catalog.Admin.GetAdminProduct;
using MolBhav.Application.Features.Catalog.Admin.GetAdminProducts;
using MolBhav.Application.Features.Catalog.Admin.GetAdminUnits;
using MolBhav.Application.Features.Catalog.Admin.UpdateCategory;
using MolBhav.Application.Features.Catalog.Admin.UpdateProduct;
using MolBhav.Application.Features.Catalog.Admin.UpdateSubCategory;
using MolBhav.Application.Features.Catalog.Admin.UpdateUnit;
using MolBhav.Application.Features.Catalog.Admin.UpdateVariant;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// Catalog administration (BRD §22): categories, sub-categories, units, products, variants. Admin role only.
/// Nothing is deleted — items are deactivated (<c>isActive: false</c>) because prices and user selections reference them.
/// Codes, and a unit's dimension/factor, are immutable after creation.
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/catalog")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminCatalogController(ISender sender) : ApiControllerBase(sender)
{
    private const string CategoriesPath = "categories";
    private const string UnitsPath = "units";

    // ------------------------------------------------------------------ categories

    /// <summary>Full category tree including inactive items and all translations.</summary>
    [HttpGet(CategoriesPath)]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminCategoryResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCategories(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminCategoriesQuery(), cancellationToken));

    /// <response code="409">Code already used (<c>ProcurementCategory.CodeTaken</c>).</response>
    [HttpPost(CategoriesPath)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateCategory([FromBody] CreateCategoryRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateCategoryCommand(
            request.Code ?? string.Empty,
            request.IconKey,
            request.DisplayOrder ?? 0,
            request.Translations ?? []);

        return CreatedEnvelope(await Sender.Send(command, cancellationToken), CollectionLocation(CategoriesPath));
    }

    [HttpPut(CategoriesPath + "/{categoryId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateCategory(Guid categoryId, [FromBody] UpdateCategoryRequest request, CancellationToken cancellationToken)
    {
        var command = new UpdateCategoryCommand(
            categoryId,
            request.IconKey,
            request.DisplayOrder ?? 0,
            request.IsActive,
            request.Translations ?? []);

        return NoContentOrProblem(await Sender.Send(command, cancellationToken));
    }

    /// <response code="409">Code already used in this category (<c>SubCategory.CodeTaken</c>).</response>
    [HttpPost(CategoriesPath + "/{categoryId:guid}/sub-categories")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> AddSubCategory(Guid categoryId, [FromBody] AddSubCategoryRequest request, CancellationToken cancellationToken)
    {
        var command = new AddSubCategoryCommand(
            categoryId,
            request.Code ?? string.Empty,
            request.DisplayOrder ?? 0,
            request.Translations ?? []);

        return CreatedEnvelope(await Sender.Send(command, cancellationToken), CollectionLocation(CategoriesPath));
    }

    [HttpPut(CategoriesPath + "/{categoryId:guid}/sub-categories/{subCategoryId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateSubCategory(
        Guid categoryId,
        Guid subCategoryId,
        [FromBody] UpdateSubCategoryRequest request,
        CancellationToken cancellationToken)
    {
        var command = new UpdateSubCategoryCommand(
            categoryId,
            subCategoryId,
            request.DisplayOrder ?? 0,
            request.IsActive,
            request.Translations ?? []);

        return NoContentOrProblem(await Sender.Send(command, cancellationToken));
    }

    // ------------------------------------------------------------------ units

    [HttpGet(UnitsPath)]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminUnitResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetUnits(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminUnitsQuery(), cancellationToken));

    /// <response code="409">Code already used (<c>UnitOfMeasure.CodeTaken</c>).</response>
    [HttpPost(UnitsPath)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateUnit([FromBody] CreateUnitRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateUnitCommand(
            request.Code ?? string.Empty,
            request.Symbol ?? string.Empty,
            request.Dimension,
            request.ToBaseFactor,
            request.Translations ?? []);

        return CreatedEnvelope(await Sender.Send(command, cancellationToken), CollectionLocation(UnitsPath));
    }

    [HttpPut(UnitsPath + "/{unitId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateUnit(Guid unitId, [FromBody] UpdateUnitRequest request, CancellationToken cancellationToken)
    {
        var command = new UpdateUnitCommand(unitId, request.Symbol ?? string.Empty, request.IsActive, request.Translations ?? []);
        return NoContentOrProblem(await Sender.Send(command, cancellationToken));
    }

    // ------------------------------------------------------------------ products

    /// <summary>Product list including inactive products; <c>name</c> is the English name.</summary>
    [HttpGet("products")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminProductSummaryResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetProducts(
        [FromQuery] string? categoryCode,
        [FromQuery] Guid? subCategoryId,
        [FromQuery] string? search,
        [FromQuery] bool? isActive,
        CancellationToken cancellationToken,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize) =>
        PagedEnvelope(await Sender.Send(
            new GetAdminProductsQuery(categoryCode, subCategoryId, search, isActive, page, pageSize),
            cancellationToken));

    [HttpGet("products/{productId:guid}")]
    [ProducesResponseType<ApiResponse<AdminProductResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetProduct(Guid productId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminProductQuery(productId), cancellationToken));

    /// <response code="400">Invalid input, or unknown sub-category / unit (<c>SubCategory.NotFound</c>, <c>UnitOfMeasure.NotFound</c>).</response>
    /// <response code="409">Code already used (<c>Product.CodeTaken</c>).</response>
    [HttpPost("products")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateProduct([FromBody] CreateProductRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateProductCommand(
            request.Code ?? string.Empty,
            request.SubCategoryId ?? Guid.Empty,
            request.DefaultUnitId ?? Guid.Empty,
            request.DisplayOrder ?? 0,
            request.ImageKey,
            request.Translations ?? []);

        return CreatedEnvelope(
            await Sender.Send(command, cancellationToken),
            nameof(GetProduct),
            created => new { productId = created.Id });
    }

    [HttpPut("products/{productId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateProduct(Guid productId, [FromBody] UpdateProductRequest request, CancellationToken cancellationToken)
    {
        var command = new UpdateProductCommand(
            productId,
            request.SubCategoryId ?? Guid.Empty,
            request.DefaultUnitId ?? Guid.Empty,
            request.DisplayOrder ?? 0,
            request.IsActive,
            request.ImageKey,
            request.Translations ?? []);

        return NoContentOrProblem(await Sender.Send(command, cancellationToken));
    }

    /// <response code="409">Code already used for this product (<c>ProductVariant.CodeTaken</c>).</response>
    [HttpPost("products/{productId:guid}/variants")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> AddVariant(Guid productId, [FromBody] AddVariantRequest request, CancellationToken cancellationToken)
    {
        var command = new AddVariantCommand(
            productId,
            request.Code ?? string.Empty,
            request.DisplayOrder ?? 0,
            request.Translations ?? []);

        return CreatedEnvelope(
            await Sender.Send(command, cancellationToken),
            nameof(GetProduct),
            _ => new { productId });
    }

    [HttpPut("products/{productId:guid}/variants/{variantId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateVariant(
        Guid productId,
        Guid variantId,
        [FromBody] UpdateVariantRequest request,
        CancellationToken cancellationToken)
    {
        var command = new UpdateVariantCommand(
            productId,
            variantId,
            request.DisplayOrder ?? 0,
            request.IsActive,
            request.Translations ?? []);

        return NoContentOrProblem(await Sender.Send(command, cancellationToken));
    }

    private string CollectionLocation(string path) => $"{Request.PathBase}/api/v1/admin/catalog/{path}";
}
