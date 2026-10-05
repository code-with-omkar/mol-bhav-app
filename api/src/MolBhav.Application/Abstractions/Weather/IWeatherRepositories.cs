using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Weather;

namespace MolBhav.Application.Abstractions.Weather;

public interface IWeatherForecastRepository : IRepository<WeatherForecast, Guid>
{
    /// <summary>The existing forecast row of each given user, keyed by user id (users with none are absent) — one query per run, not per user.</summary>
    Task<IReadOnlyDictionary<Guid, WeatherForecast>> GetByUserIdsAsync(IReadOnlyCollection<Guid> userIds, CancellationToken cancellationToken = default);
}
