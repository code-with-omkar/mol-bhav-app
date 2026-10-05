namespace MolBhav.Application.Features.Weather.Models;

public sealed record WeatherDayResponse(
    DateOnly Date,
    decimal? MinTempC,
    decimal? MaxTempC,
    decimal? RainfallMm,
    int? HumidityPercent,
    string Condition);

/// <summary>The signed-in user's 7-day forecast for the IMD station that represents their state.</summary>
public sealed record WeatherForecastResponse(
    string StationCode,
    string StationName,
    DateOnly ForecastDate,
    DateTimeOffset FetchedAtUtc,
    IReadOnlyList<WeatherDayResponse> Days);

/// <summary>An eligible user for a weather run; <paramref name="ForecastDate"/> is the date of the forecast they already hold, if any.</summary>
public sealed record WeatherIngestionTarget(Guid UserId, string State, DateOnly? ForecastDate);

/// <summary>
/// What one weather run did. <paramref name="Failures"/> carries one reason per station that could not be fetched
/// (capped), so an admin sees why without opening logs.
/// </summary>
public sealed record WeatherRunResponse(
    int UsersTargeted,
    int Refreshed,
    int SkippedFresh,
    int SkippedNoStation,
    int Failed,
    IReadOnlyList<string> Failures);
