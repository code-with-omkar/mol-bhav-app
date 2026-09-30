using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Alerting;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Alerting.CreateAlertRule;
using MolBhav.Application.Features.Alerting.DeleteAlertRule;
using MolBhav.Application.Features.Alerting.GetAlertRules;
using MolBhav.Application.Features.Alerting.GetAlerts;
using MolBhav.Application.Features.Alerting.MarkAlertRead;
using MolBhav.Application.Features.Alerting.Models;
using MolBhav.Application.Features.Alerting.UpdateAlertRule;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>The signed-in user's price-move watches and inbox (BRD §15). Requires a signed-in user (fallback auth policy).</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/alert-rules")]
public sealed class AlertingController(ISender sender) : ApiControllerBase(sender)
{
    [HttpGet]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AlertRuleResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAlertRules(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAlertRulesQuery(), cancellationToken));

    /// <response code="404">Unknown product/variant/mandi/supplier.</response>
    [HttpPost]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateAlertRule([FromBody] CreateAlertRuleRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateAlertRuleCommand(
            request.ProductId ?? Guid.Empty,
            request.VariantId,
            request.LocationKind,
            request.MandiId,
            request.SupplierId,
            request.ThresholdType,
            request.ThresholdPercent,
            request.ThresholdPrice);

        return CreatedEnvelope(await Sender.Send(command, cancellationToken), $"{Request.PathBase}/api/v1/alert-rules");
    }

    [HttpPut("{alertRuleId:guid}")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateAlertRule(Guid alertRuleId, [FromBody] UpdateAlertRuleRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(
            new UpdateAlertRuleCommand(alertRuleId, request.ThresholdPercent, request.ThresholdPrice, request.IsActive), cancellationToken));

    [HttpDelete("{alertRuleId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> DeleteAlertRule(Guid alertRuleId, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new DeleteAlertRuleCommand(alertRuleId), cancellationToken));

    [HttpGet("/api/v{version:apiVersion}/alerts")]
    [ProducesResponseType<ApiResponse<PagedResult<AlertResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAlerts([FromQuery] int page = 1, [FromQuery] int pageSize = PageRequest.DefaultPageSize, CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetAlertsQuery(page, pageSize), cancellationToken));

    [HttpPost("/api/v{version:apiVersion}/alerts/{alertId:guid}/read")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> MarkAlertRead(Guid alertId, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new MarkAlertReadCommand(alertId), cancellationToken));
}
