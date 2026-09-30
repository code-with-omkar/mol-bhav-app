using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Procurement;
using MolBhav.Api.Setup;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Procurement.Admin.CreateCostComponent;
using MolBhav.Application.Features.Procurement.Admin.GetAdminCostComponents;
using MolBhav.Application.Features.Procurement.Admin.UpdateCostComponent;
using MolBhav.Application.Features.Procurement.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// Cost-component administration for the Procurement Opportunity Engine's landed-cost estimate (BRD §17/§25:
/// freight/handling/tax/supplier-terms). Admin role only. Deactivated, never deleted.
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/procurement")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminProcurementController(ISender sender) : ApiControllerBase(sender)
{
    private const string CostComponentsPath = "cost-components";

    [HttpGet(CostComponentsPath)]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminCostComponentResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCostComponents(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminCostComponentsQuery(), cancellationToken));

    /// <response code="409">Code already used (<c>CostComponent.CodeAlreadyExists</c>).</response>
    [HttpPost(CostComponentsPath)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateCostComponent([FromBody] CreateCostComponentRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateCostComponentCommand(request.Code, request.Name, request.ComponentType, request.Value);
        return CreatedEnvelope(await Sender.Send(command, cancellationToken), $"{Request.PathBase}/api/v1/admin/procurement/{CostComponentsPath}");
    }

    [HttpPut($"{CostComponentsPath}/{{costComponentId:guid}}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateCostComponent(Guid costComponentId, [FromBody] UpdateCostComponentRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new UpdateCostComponentCommand(costComponentId, request.Name, request.Value, request.IsActive), cancellationToken));
}
