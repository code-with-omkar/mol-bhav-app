using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Weather;
using MolBhav.Application.Features.Weather.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Weather.GetWeatherForecast;

internal sealed class GetWeatherForecastQueryHandler(IWeatherReadService readService, ICurrentUser currentUser)
    : IQueryHandler<GetWeatherForecastQuery, WeatherForecastResponse>
{
    public async Task<Result<WeatherForecastResponse>> Handle(GetWeatherForecastQuery request, CancellationToken cancellationToken)
    {
        var userId = request.UserId ?? currentUser.GetRequiredUserId();
        var forecast = await readService.GetForecastAsync(userId, cancellationToken);

        return forecast is null
            ? Error.NotFound("Weather.ForecastNotFound", "No forecast yet — set your state in your profile; forecasts refresh daily.")
            : forecast;
    }
}
