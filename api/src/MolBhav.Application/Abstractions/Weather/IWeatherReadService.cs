using MolBhav.Application.Features.Weather.Models;

namespace MolBhav.Application.Abstractions.Weather;

/// <summary>Dapper-backed reads for the weather module.</summary>
public interface IWeatherReadService
{
    /// <summary>The user's current forecast, or null when none has been fetched yet.</summary>
    Task<WeatherForecastResponse?> GetForecastAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Active (not deleted) users with a state on their profile — the only users a forecast can be fetched for —
    /// optionally narrowed to one user, each with the date of the forecast they already hold.
    /// </summary>
    Task<IReadOnlyList<WeatherIngestionTarget>> GetIngestionTargetsAsync(Guid? userId, CancellationToken cancellationToken = default);
}
