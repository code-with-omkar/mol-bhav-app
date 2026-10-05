using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Weather;
using MolBhav.Domain.Weather;

namespace MolBhav.Infrastructure.Persistence.Repositories.Weather;

internal sealed class WeatherForecastRepository(MolBhavDbContext dbContext) : Repository<WeatherForecast, Guid>(dbContext), IWeatherForecastRepository
{
    public async Task<IReadOnlyDictionary<Guid, WeatherForecast>> GetByUserIdsAsync(
        IReadOnlyCollection<Guid> userIds, CancellationToken cancellationToken = default)
    {
        if (userIds.Count == 0)
        {
            return new Dictionary<Guid, WeatherForecast>();
        }

        // Served by the unique (user_id) index.
        return await Set.Where(f => userIds.Contains(f.UserId)).ToDictionaryAsync(f => f.UserId, cancellationToken);
    }
}
