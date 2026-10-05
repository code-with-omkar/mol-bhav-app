using System.Globalization;
using System.Net;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Weather;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Weather;

namespace MolBhav.Infrastructure.Weather;

/// <summary>
/// IMD forecast adapter: fetches one station's forecast and maps it to up to seven <see cref="WeatherDay"/>s. Retries
/// (3×, backoff) and timeouts live in the named client's resilience handler, so this class only maps outcomes to an
/// honest <see cref="WeatherFetchResult"/> — it never invents data when IMD is unreachable or unconfigured.
/// IMD's field names are matched leniently (several spellings per field) because the gateway's schema is not pinned
/// here; a row with no parseable date is skipped, and a response with no usable rows is a failure.
/// </summary>
internal sealed partial class ImdHttpClient(
    IHttpClientFactory httpClientFactory,
    IOptions<ImdOptions> options,
    TimeProvider timeProvider,
    ILogger<ImdHttpClient> logger) : IWeatherForecastSource
{
    public const string HttpClientName = "imd";

    private static readonly string[] DateKeys = ["date", "forecast_date", "valid_date", "day"];
    private static readonly string[] MinKeys = ["min_temp", "tmin", "min_temperature", "temp_min", "minimum"];
    private static readonly string[] MaxKeys = ["max_temp", "tmax", "max_temperature", "temp_max", "maximum"];
    private static readonly string[] RainKeys = ["rainfall", "rain", "rainfall_mm", "precipitation"];
    private static readonly string[] HumidityKeys = ["humidity", "rh", "relative_humidity"];
    private static readonly string[] ConditionKeys = ["weather", "forecast", "condition", "weather_desc", "description"];
    private static readonly string[] ListKeys = ["forecast", "data", "forecasts", "days"];
    private static readonly string[] DateFormats = ["yyyy-MM-dd", "dd-MM-yyyy", "dd/MM/yyyy", "yyyy/MM/dd"];

    public async Task<WeatherFetchResult> FetchAsync(ImdStation station, CancellationToken cancellationToken = default)
    {
        var opts = options.Value;

        if (opts.UseMockData)
        {
            return await FetchMockAsync(station, opts, cancellationToken);
        }

        if (string.IsNullOrWhiteSpace(opts.ApiKey))
        {
            LogMissingApiKey(logger);
            return WeatherFetchResult.Failed("Imd:ApiKey is not configured. Set it via user-secrets or the Imd__ApiKey environment variable.");
        }

        var stationId = opts.StationCodeMap.TryGetValue(station.Code, out var mapped) ? mapped : station.Code;
        var path = opts.ForecastPathTemplate.Replace("{station}", Uri.EscapeDataString(stationId), StringComparison.Ordinal);

        try
        {
            var client = httpClientFactory.CreateClient(HttpClientName);
            using var request = new HttpRequestMessage(HttpMethod.Get, path);
            request.Headers.TryAddWithoutValidation(opts.ApiKeyHeader, opts.ApiKey);

            using var response = await client.SendAsync(request, cancellationToken);
            if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden)
            {
                LogUnauthorized(logger, station.Code);
                return WeatherFetchResult.Failed("IMD rejected the API key. Check Imd:ApiKey.");
            }

            if (!response.IsSuccessStatusCode)
            {
                LogBadStatus(logger, station.Code, (int)response.StatusCode);
                return WeatherFetchResult.Failed($"IMD returned HTTP {(int)response.StatusCode} for station '{station.Code}'.");
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
            return Map(document.RootElement, station);
        }
        catch (JsonException ex)
        {
            LogUnexpected(logger, station.Code, ex);
            return WeatherFetchResult.Failed("IMD returned a response that is not valid JSON.");
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException && !cancellationToken.IsCancellationRequested)
        {
            LogUnexpected(logger, station.Code, ex);
            return WeatherFetchResult.Failed($"IMD request failed after {ImdOptions.RetryAttempts} retries: {ex.Message}");
        }
    }

    /// <summary>Development-only (enforced in DI): the fixture is parsed like a live response, then re-dated to start today (IST).</summary>
    private async Task<WeatherFetchResult> FetchMockAsync(ImdStation station, ImdOptions opts, CancellationToken cancellationToken)
    {
        var path = Path.IsPathRooted(opts.MockDataPath)
            ? opts.MockDataPath
            : Path.Combine(AppContext.BaseDirectory, opts.MockDataPath);

        if (!File.Exists(path))
        {
            return WeatherFetchResult.Failed($"IMD mock data file not found at '{path}'.");
        }

        try
        {
            await using var stream = File.OpenRead(path);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
            var mapped = Map(document.RootElement, station);
            if (!mapped.IsSuccess)
            {
                return mapped;
            }

            var today = IngestionDates.TodayIst(timeProvider.GetUtcNow());
            var days = mapped.Days.Select((d, i) => d with { Date = today.AddDays(i) }).ToArray();

            LogMockUsed(logger, station.Code, path, days.Length);
            return WeatherFetchResult.Success(days);
        }
        catch (JsonException ex)
        {
            return WeatherFetchResult.Failed($"IMD mock data file is not valid JSON: {ex.Message}");
        }
    }

    private static WeatherFetchResult Map(JsonElement root, ImdStation station)
    {
        var list = FindList(root);
        if (list is null)
        {
            return WeatherFetchResult.Failed($"IMD response for '{station.Code}' has no forecast list.");
        }

        var days = new List<WeatherDay>();
        foreach (var item in list.Value.EnumerateArray())
        {
            if (item.ValueKind != JsonValueKind.Object || ReadDate(item) is not { } date)
            {
                continue;
            }

            days.Add(new WeatherDay(
                date,
                ReadDecimal(item, MinKeys),
                ReadDecimal(item, MaxKeys),
                ReadDecimal(item, RainKeys),
                ReadDecimal(item, HumidityKeys) is { } humidity ? (int)Math.Round(humidity) : null,
                ReadString(item, ConditionKeys) ?? string.Empty));
        }

        return days.Count == 0
            ? WeatherFetchResult.Failed($"IMD response for '{station.Code}' had no usable forecast days.")
            : WeatherFetchResult.Success(days.OrderBy(d => d.Date).DistinctBy(d => d.Date).Take(WeatherForecast.MaxDays).ToArray());
    }

    private static JsonElement? FindList(JsonElement root)
    {
        if (root.ValueKind == JsonValueKind.Array)
        {
            return root;
        }

        if (root.ValueKind != JsonValueKind.Object)
        {
            return null;
        }

        foreach (var key in ListKeys)
        {
            if (TryGetProperty(root, key, out var value) && value.ValueKind == JsonValueKind.Array)
            {
                return value;
            }
        }

        return null;
    }

    private static bool TryGetProperty(JsonElement element, string name, out JsonElement value)
    {
        foreach (var property in element.EnumerateObject())
        {
            if (string.Equals(property.Name, name, StringComparison.OrdinalIgnoreCase))
            {
                value = property.Value;
                return true;
            }
        }

        value = default;
        return false;
    }

    private static DateOnly? ReadDate(JsonElement item)
    {
        var text = ReadString(item, DateKeys);
        return text is not null && DateOnly.TryParseExact(text, DateFormats, CultureInfo.InvariantCulture, DateTimeStyles.None, out var date)
            ? date
            : null;
    }

    private static decimal? ReadDecimal(JsonElement item, string[] keys)
    {
        foreach (var key in keys)
        {
            if (!TryGetProperty(item, key, out var value))
            {
                continue;
            }

            if (value.ValueKind == JsonValueKind.Number && value.TryGetDecimal(out var number))
            {
                return number;
            }

            if (value.ValueKind == JsonValueKind.String
                && decimal.TryParse(value.GetString(), NumberStyles.Float, CultureInfo.InvariantCulture, out var parsed))
            {
                return parsed;
            }
        }

        return null;
    }

    private static string? ReadString(JsonElement item, string[] keys)
    {
        foreach (var key in keys)
        {
            if (TryGetProperty(item, key, out var value) && value.ValueKind == JsonValueKind.String
                && !string.IsNullOrWhiteSpace(value.GetString()))
            {
                return value.GetString()!.Trim();
            }
        }

        return null;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "[IMD MOCK] Station {StationCode} served from fixture {Path}: {DayCount} days — not live data")]
    private static partial void LogMockUsed(ILogger logger, string stationCode, string path, int dayCount);

    [LoggerMessage(Level = LogLevel.Warning, Message = "[IMD] ApiKey is not configured — skipping fetch")]
    private static partial void LogMissingApiKey(ILogger logger);

    [LoggerMessage(Level = LogLevel.Warning, Message = "[IMD] Unauthorised response for station {StationCode} — check ApiKey")]
    private static partial void LogUnauthorized(ILogger logger, string stationCode);

    [LoggerMessage(Level = LogLevel.Warning, Message = "[IMD] HTTP {StatusCode} for station {StationCode}")]
    private static partial void LogBadStatus(ILogger logger, string stationCode, int statusCode);

    [LoggerMessage(Level = LogLevel.Error, Message = "[IMD] Fetch failed for station {StationCode}")]
    private static partial void LogUnexpected(ILogger logger, string stationCode, Exception exception);
}
