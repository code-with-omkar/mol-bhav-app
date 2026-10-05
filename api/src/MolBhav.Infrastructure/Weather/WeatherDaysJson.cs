using System.Text.Json;
using MolBhav.Domain.Weather;

namespace MolBhav.Infrastructure.Weather;

/// <summary>The one JSON shape of <c>WeatherForecast.Days</c> in the jsonb column — shared by the EF mapping and the Dapper read.</summary>
internal static class WeatherDaysJson
{
    private static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web);

    public static string Serialize(IReadOnlyList<WeatherDay> days) => JsonSerializer.Serialize(days, Options);

    public static IReadOnlyList<WeatherDay> Deserialize(string json) =>
        JsonSerializer.Deserialize<List<WeatherDay>>(json, Options) ?? [];
}
