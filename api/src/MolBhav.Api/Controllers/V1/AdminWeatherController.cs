using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Setup;
using MolBhav.Application.Features.Weather.Admin.RunWeatherIngestionJob;
using MolBhav.Application.Features.Weather.GetWeatherForecast;
using MolBhav.Application.Features.Weather.Models;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Manual weather refresh and per-user forecast inspection. Admin role only.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/weather")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminWeatherController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>
    /// Refetches forecasts now — for every eligible user, or just <paramref name="userId"/>. Always refetches (unlike the
    /// daily scheduler, which skips users who already hold today's forecast) and replaces the stored forecast.
    /// </summary>
    /// <response code="404">The given user is unknown, inactive, or has no state on their profile (<c>Weather.UserNotEligible</c>).</response>
    [HttpPost("run")]
    [ProducesResponseType<ApiResponse<WeatherRunResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Run([FromQuery] Guid? userId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new RunWeatherIngestionJobCommand(userId, IngestionTriggerType.Manual), cancellationToken));

    /// <summary>One user's stored forecast, as the app would see it.</summary>
    /// <response code="404">That user has no forecast yet (<c>Weather.ForecastNotFound</c>).</response>
    [HttpGet("users/{userId:guid}/forecast")]
    [ProducesResponseType<ApiResponse<WeatherForecastResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetUserForecast(Guid userId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetWeatherForecastQuery(userId), cancellationToken));
}
