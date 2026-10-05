using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Weather;
using MolBhav.Application.Features.Weather.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Weather;

namespace MolBhav.Application.Features.Weather.Admin.RunWeatherIngestionJob;

/// <summary>
/// Refreshes each eligible user's forecast. Users are grouped by their IMD station so a station is fetched once per run
/// however many users share it (36 stations bound the upstream calls); every user still gets their own row, replaced
/// in place — no history. A station that cannot be fetched fails only its own users and never aborts the rest, and the
/// previous forecast stays untouched (stale beats empty). All writes commit in one transaction (<c>UnitOfWorkBehavior</c>).
/// </summary>
internal sealed class RunWeatherIngestionJobCommandHandler(
    IWeatherReadService readService,
    IWeatherForecastRepository forecasts,
    IWeatherForecastSource source,
    TimeProvider timeProvider) : ICommandHandler<RunWeatherIngestionJobCommand, WeatherRunResponse>
{
    private const int MaxReportedFailures = 10;

    public async Task<Result<WeatherRunResponse>> Handle(RunWeatherIngestionJobCommand request, CancellationToken cancellationToken)
    {
        var now = timeProvider.GetUtcNow();
        var today = IngestionDates.TodayIst(now);

        var targets = await readService.GetIngestionTargetsAsync(request.UserId, cancellationToken);
        if (request.UserId is not null && targets.Count == 0)
        {
            return Error.NotFound("Weather.UserNotEligible", "No active user with that id has a state on their profile.");
        }

        var skippedFresh = 0;
        var skippedNoStation = 0;
        var due = new List<(WeatherIngestionTarget Target, ImdStation Station)>();

        foreach (var target in targets)
        {
            var station = ImdStationDirectory.ForState(target.State);
            if (station is null)
            {
                skippedNoStation++;
            }
            else if (request.TriggerType == IngestionTriggerType.Scheduled && target.ForecastDate == today)
            {
                skippedFresh++;
            }
            else
            {
                due.Add((target, station));
            }
        }

        var existing = await forecasts.GetByUserIdsAsync(due.Select(d => d.Target.UserId).ToArray(), cancellationToken);

        var refreshed = 0;
        var failed = 0;
        var failures = new List<string>();

        foreach (var stationGroup in due.GroupBy(d => d.Station.Code))
        {
            var station = stationGroup.First().Station;
            var fetch = await source.FetchAsync(station, cancellationToken);
            if (!fetch.IsSuccess)
            {
                failed += stationGroup.Count();
                if (failures.Count < MaxReportedFailures)
                {
                    failures.Add($"{station.Name}: {fetch.FailureReason ?? "fetch failed with no reason given"}");
                }

                continue;
            }

            foreach (var (target, _) in stationGroup)
            {
                var written = existing.TryGetValue(target.UserId, out var forecast)
                    ? forecast.Replace(station.Code, today, fetch.Days, now)
                    : AddNew(target.UserId, station.Code, today, fetch.Days, now);

                if (written.IsSuccess)
                {
                    refreshed++;
                }
                else
                {
                    failed++;
                    if (failures.Count < MaxReportedFailures)
                    {
                        failures.Add($"{station.Name}: {written.Error.Description}");
                    }
                }
            }
        }

        return new WeatherRunResponse(targets.Count, refreshed, skippedFresh, skippedNoStation, failed, failures);
    }

    private Result AddNew(Guid userId, string stationCode, DateOnly forecastDate, IReadOnlyList<WeatherDay> days, DateTimeOffset now)
    {
        var created = WeatherForecast.Create(userId, stationCode, forecastDate, days, now);
        if (created.IsFailure)
        {
            return Result.Failure(created.Error);
        }

        forecasts.Add(created.Value);
        return Result.Success();
    }
}
