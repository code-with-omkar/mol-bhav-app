using Dapper;
using MolBhav.Application.Abstractions.Weather;
using MolBhav.Application.Features.Weather.Models;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Weather;
using MolBhav.Infrastructure.Persistence.Configurations.Identity;
using MolBhav.Infrastructure.Persistence.Configurations.Weather;
using MolBhav.Infrastructure.Weather;

namespace MolBhav.Infrastructure.Persistence.Read.Weather;

internal sealed class WeatherReadService(IDbConnectionFactory connectionFactory) : IWeatherReadService
{
    private const string Forecasts = WeatherForecastConfiguration.QualifiedTableName;
    private const string Users = UserConfiguration.QualifiedTableName;

    private const string ForecastSql = $"""
        SELECT station_code, forecast_date, fetched_at_utc, days::text AS days_json
        FROM {Forecasts}
        WHERE user_id = @UserId;
        """;

    // Soft-deleted and suspended users never get a forecast; users with no state cannot be mapped to a station.
    private const string TargetsSql = $"""
        SELECT u.id AS user_id, u.state, f.forecast_date
        FROM {Users} u
        LEFT JOIN {Forecasts} f ON f.user_id = u.id
        WHERE NOT u.is_deleted
          AND u.status = @Active
          AND u.state IS NOT NULL
          AND (@UserId IS NULL OR u.id = @UserId)
        ORDER BY u.id;
        """;

    public async Task<WeatherForecastResponse?> GetForecastAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var row = await connection.QuerySingleOrDefaultAsync<ForecastRow>(
            new CommandDefinition(ForecastSql, new { UserId = userId }, cancellationToken: cancellationToken));
        if (row is null)
        {
            return null;
        }

        var stationName = ImdStationDirectory.All.FirstOrDefault(s => s.Code == row.StationCode)?.Name ?? row.StationCode;
        var days = WeatherDaysJson.Deserialize(row.DaysJson)
            .Select(d => new WeatherDayResponse(d.Date, d.MinTempC, d.MaxTempC, d.RainfallMm, d.HumidityPercent, d.Condition))
            .ToArray();

        return new WeatherForecastResponse(row.StationCode, stationName, row.ForecastDate, row.FetchedAtUtc, days);
    }

    public async Task<IReadOnlyList<WeatherIngestionTarget>> GetIngestionTargetsAsync(Guid? userId, CancellationToken cancellationToken = default)
    {
        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<TargetRow>(
            new CommandDefinition(TargetsSql, new { Active = nameof(UserStatus.Active), UserId = userId }, cancellationToken: cancellationToken));

        return rows.Select(r => new WeatherIngestionTarget(r.UserId, r.State, r.ForecastDate)).ToArray();
    }

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class ForecastRow
    {
        public string StationCode { get; init; } = string.Empty;

        public DateOnly ForecastDate { get; init; }

        public DateTimeOffset FetchedAtUtc { get; init; }

        public string DaysJson { get; init; } = "[]";
    }

    private sealed class TargetRow
    {
        public Guid UserId { get; init; }

        public string State { get; init; } = string.Empty;

        public DateOnly? ForecastDate { get; init; }
    }
#pragma warning restore CA1812
}
