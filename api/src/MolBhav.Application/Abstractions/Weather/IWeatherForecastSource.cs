using MolBhav.Domain.Weather;

namespace MolBhav.Application.Abstractions.Weather;

/// <summary>
/// Where forecasts come from (IMD today). The handler never knows the vendor — swap the implementation to change
/// provider. One call returns the forecast for one station; the handler shares it between every user mapped to it.
/// </summary>
public interface IWeatherForecastSource
{
    Task<WeatherFetchResult> FetchAsync(ImdStation station, CancellationToken cancellationToken = default);
}

/// <summary>Outcome of one station fetch: the days on success, otherwise an honest reason (never fabricated data).</summary>
public sealed record WeatherFetchResult(bool IsSuccess, IReadOnlyList<WeatherDay> Days, string? FailureReason)
{
    public static WeatherFetchResult Success(IReadOnlyList<WeatherDay> days) => new(true, days, null);

    public static WeatherFetchResult Failed(string reason) => new(false, [], reason);
}
