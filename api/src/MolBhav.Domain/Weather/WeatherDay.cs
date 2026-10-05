namespace MolBhav.Domain.Weather;

/// <summary>
/// One day of an IMD forecast. A value object stored inside <see cref="WeatherForecast.Days"/> as JSON — the forecast is
/// always read and replaced as a whole, so it has no table or identity of its own. Temperatures are °C, rainfall mm.
/// </summary>
public sealed record WeatherDay(
    DateOnly Date,
    decimal? MinTempC,
    decimal? MaxTempC,
    decimal? RainfallMm,
    int? HumidityPercent,
    string Condition);
