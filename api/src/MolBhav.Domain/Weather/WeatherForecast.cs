using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Weather;

/// <summary>
/// A user's current IMD forecast: the <see cref="Days"/> (up to seven) for the IMD station that represents their state,
/// denormalised as one JSON array so the app reads it with a single row. One row per user — each daily refresh
/// <see cref="Replace"/>s it, there is no historical archive. <see cref="ForecastDate"/> is the IST day the forecast was
/// issued for; the scheduler skips a user whose row already carries today's date, which makes runs idempotent.
/// </summary>
public sealed class WeatherForecast : AggregateRoot<Guid>, IAuditableEntity
{
    public const int MaxDays = 7;
    public const int StationCodeMaxLength = 50;

    private WeatherForecast(Guid id, Guid userId)
        : base(id)
    {
        UserId = userId;
        StationCode = string.Empty;
        Days = [];
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private WeatherForecast()
    {
        StationCode = string.Empty;
        Days = [];
    }

    public Guid UserId { get; private set; }

    /// <summary>The IST date this forecast was issued for (the first day of <see cref="Days"/> is normally this date).</summary>
    public DateOnly ForecastDate { get; private set; }

    public string StationCode { get; private set; }

    public IReadOnlyList<WeatherDay> Days { get; private set; }

    public DateTimeOffset FetchedAtUtc { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<WeatherForecast> Create(
        Guid userId, string stationCode, DateOnly forecastDate, IReadOnlyList<WeatherDay> days, DateTimeOffset fetchedAtUtc)
    {
        if (userId == Guid.Empty)
        {
            return Error.Validation("WeatherForecast.UserRequired", "User is required.");
        }

        var forecast = new WeatherForecast(Guid.CreateVersion7(), userId);
        var replaced = forecast.Replace(stationCode, forecastDate, days, fetchedAtUtc);
        return replaced.IsFailure ? Result.Failure<WeatherForecast>(replaced.Error) : forecast;
    }

    /// <summary>Overwrites the whole forecast (new day, new station if the user moved state, or a same-day re-run).</summary>
    public Result Replace(string stationCode, DateOnly forecastDate, IReadOnlyList<WeatherDay> days, DateTimeOffset fetchedAtUtc)
    {
        if (string.IsNullOrWhiteSpace(stationCode) || stationCode.Length > StationCodeMaxLength)
        {
            return Error.Validation("WeatherForecast.StationInvalid", "A station code of up to 50 characters is required.");
        }

        if (days.Count is 0 or > MaxDays)
        {
            return Error.Validation("WeatherForecast.DaysInvalid", $"A forecast needs between 1 and {MaxDays} days.");
        }

        StationCode = stationCode;
        ForecastDate = forecastDate;
        Days = days.OrderBy(d => d.Date).ToArray();
        FetchedAtUtc = fetchedAtUtc;
        return Result.Success();
    }
}
