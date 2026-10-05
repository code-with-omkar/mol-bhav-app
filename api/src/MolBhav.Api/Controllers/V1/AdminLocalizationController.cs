using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Localization;
using MolBhav.Api.Setup;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Localization.Admin.CreateLocalizedText;
using MolBhav.Application.Features.Localization.Admin.GetAdminLocalizedText;
using MolBhav.Application.Features.Localization.Admin.GetAdminLocalizedTexts;
using MolBhav.Application.Features.Localization.Admin.UpdateLocalizedText;
using MolBhav.Application.Features.Localization.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// Data-driven terminology administration (BRD §8/§18: "LocalizedTexts"). Admin role only.
/// Keys are immutable once created — other modules reference them by string, so nothing is ever deleted, only
/// its translations and description are edited.
/// </summary>
[EvictReferenceDataCache] // edits here change cached catalog / market / plan / translation responses
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/localization/texts")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminLocalizationController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>All keys, optionally restricted to one namespace (e.g. <c>alerts.</c>), with every translation.</summary>
    [HttpGet]
    [ProducesResponseType<ApiResponse<PagedResult<AdminLocalizedTextResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetTexts(
        [FromQuery] string? keyPrefix,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize,
        CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetAdminLocalizedTextsQuery(keyPrefix, page, pageSize), cancellationToken));

    /// <response code="404">Unknown key (<c>LocalizedTextEntry.NotFound</c>).</response>
    [HttpGet("{localizedTextId:guid}")]
    [ProducesResponseType<ApiResponse<AdminLocalizedTextResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetText(Guid localizedTextId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminLocalizedTextQuery(localizedTextId), cancellationToken));

    /// <response code="409">Key already used (<c>LocalizedTextEntry.KeyTaken</c>).</response>
    [HttpPost]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateText([FromBody] CreateLocalizedTextRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateLocalizedTextCommand(request.Key ?? string.Empty, request.Description, request.Translations ?? []);
        return CreatedEnvelope(await Sender.Send(command, cancellationToken), $"{Request.PathBase}/api/v1/admin/localization/texts");
    }

    /// <response code="404">Unknown key (<c>LocalizedTextEntry.NotFound</c>).</response>
    [HttpPut("{localizedTextId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateText(Guid localizedTextId, [FromBody] UpdateLocalizedTextRequest request, CancellationToken cancellationToken)
    {
        var command = new UpdateLocalizedTextCommand(localizedTextId, request.Description, request.Translations ?? []);
        return NoContentOrProblem(await Sender.Send(command, cancellationToken));
    }
}
