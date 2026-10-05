namespace MolBhav.Infrastructure.Weather;

/// <summary>
/// Configuration for the IMD forecast adapter and the daily weather refresh. <c>ApiKey</c> must be supplied via
/// user-secrets or environment (<c>Imd__ApiKey</c>) — never appsettings plain text.
/// </summary>
public sealed class ImdOptions
{
    public const string SectionName = "Imd";

    public const int RetryAttempts = 3;

    public string BaseAddress { get; set; } = "https://api.imd.gov.in";

    /// <summary>Path (relative to <see cref="BaseAddress"/>) of one station's forecast; <c>{station}</c> is replaced by the station code.</summary>
    public string ForecastPathTemplate { get; set; } = "/api/v1/forecast/city/{station}";

    /// <summary>Sent as the <see cref="ApiKeyHeader"/> header when set; IMD's gateway issues keys per registered account.</summary>
    public string ApiKey { get; set; } = string.Empty;

    public string ApiKeyHeader { get; set; } = "x-api-key";

    /// <summary>Per-attempt timeout; the resilience handler retries <see cref="RetryAttempts"/> times on transient failures.</summary>
    public int RequestTimeoutSeconds { get; set; } = 15;

    /// <summary>Our station code → the id IMD expects, for stations whose code differs. Keys are case-insensitive.</summary>
    public Dictionary<string, string> StationCodeMap { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>Master switch for the automatic daily refresh (the admin "run" endpoint always works).</summary>
    public bool ScheduleEnabled { get; set; } = true;

    /// <summary>IST wall-clock <c>HH:mm</c> after which the day's refresh may run.</summary>
    public string DailyRunTimeIst { get; set; } = "06:00";

    /// <summary>Minimum gap between automatic attempts, so an IMD outage is retried gently rather than every poll.</summary>
    public int RetryAfterMinutes { get; set; } = 30;

    /// <summary>Development only (startup fails elsewhere): serve <see cref="MockDataPath"/> instead of calling IMD.</summary>
    public bool UseMockData { get; set; }

    /// <summary>Fixture in the shape the adapter parses; relative paths resolve against the app's output directory.</summary>
    public string MockDataPath { get; set; } = "SampleData/imd-sample.json";
}
