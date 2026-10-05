using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Weather.Models;

namespace MolBhav.Application.Features.Weather.GetWeatherForecast;

/// <summary>A user's forecast. <paramref name="UserId"/> null means the signed-in user (the app); admins pass an id.</summary>
public sealed record GetWeatherForecastQuery(Guid? UserId = null) : IQuery<WeatherForecastResponse>;
