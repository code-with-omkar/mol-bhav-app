using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Application.Features.Weather.GetWeatherForecast;
using MolBhav.Application.Features.Weather.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>The signed-in user's IMD weather forecast. Requires a signed-in user (fallback auth policy).</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/weather")]
public sealed class WeatherController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>The 7-day forecast for the IMD station that represents the user's profile state.</summary>
    /// <response code="404">No forecast yet — the user has no (recognised) state, or the first daily refresh has not run (<c>Weather.ForecastNotFound</c>).</response>
    [HttpGet("forecast")]
    [ProducesResponseType<ApiResponse<WeatherForecastResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetForecast(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetWeatherForecastQuery(), cancellationToken));
}
