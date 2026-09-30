using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Procurement;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Procurement.ComputeOpportunities;
using MolBhav.Application.Features.Procurement.CreateRequirement;
using MolBhav.Application.Features.Procurement.DeleteRequirement;
using MolBhav.Application.Features.Procurement.GetMyRequirements;
using MolBhav.Application.Features.Procurement.GetOpportunities;
using MolBhav.Application.Features.Procurement.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>The signed-in user's procurement requirements and computed sourcing opportunities (BRD §13/§17). Requires a signed-in user.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/procurement/requirements")]
public sealed class ProcurementController(ISender sender) : ApiControllerBase(sender)
{
    [HttpGet]
    [ProducesResponseType<ApiResponse<IReadOnlyList<ProcurementRequirementResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyRequirements(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetMyRequirementsQuery(), cancellationToken));

    /// <response code="404">Unknown product, variant or district.</response>
    [HttpPost]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateRequirement([FromBody] CreateRequirementRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateRequirementCommand(
            request.ProductId ?? Guid.Empty,
            request.VariantId,
            request.Quantity ?? 0m,
            request.UnitId ?? Guid.Empty,
            request.TargetDistrictId,
            request.TargetPrice);

        return CreatedEnvelope(await Sender.Send(command, cancellationToken), $"{Request.PathBase}/api/v1/procurement/requirements");
    }

    [HttpDelete("{requirementId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> DeleteRequirement(Guid requirementId, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new DeleteRequirementCommand(requirementId), cancellationToken));

    /// <summary>Refreshes the requirement's opportunity list against current prices (a new snapshot batch each call).</summary>
    [HttpPost("{requirementId:guid}/opportunities")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<ProcurementOpportunityResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> ComputeOpportunities(Guid requirementId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new ComputeOpportunitiesCommand(requirementId), cancellationToken));

    [HttpGet("{requirementId:guid}/opportunities")]
    [ProducesResponseType<ApiResponse<IReadOnlyList<ProcurementOpportunityResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetOpportunities(Guid requirementId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetOpportunitiesQuery(requirementId), cancellationToken));
}
