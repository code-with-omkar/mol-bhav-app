using System.Globalization;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace MolBhav.Infrastructure.Monetization;

/// <summary>Where SSV public keys come from; split out so the verifier can be tested with local keys.</summary>
internal interface IAdMobVerifierKeySource
{
    /// <summary>The PEM-encoded public key for <paramref name="keyId"/>, or <c>null</c> when Google publishes none.</summary>
    Task<string?> GetPemAsync(long keyId, CancellationToken cancellationToken = default);
}

/// <summary>
/// Caches Google's key list in memory (singleton) and refreshes it when it ages out or an unknown key id appears —
/// the latter rate-limited, because the key id arrives in an unauthenticated request.
/// </summary>
internal sealed partial class AdMobVerifierKeySource(
    IHttpClientFactory httpClientFactory,
    IOptions<AdMobOptions> options,
    TimeProvider timeProvider,
    ILogger<AdMobVerifierKeySource> logger) : IAdMobVerifierKeySource, IDisposable
{
    public const string HttpClientName = "admob-ssv-keys";

    private readonly SemaphoreSlim _refreshLock = new(1, 1);
    // Replaced wholesale on refresh (never mutated), so readers always see a complete snapshot.
    private Dictionary<long, string> _keys = [];
    private DateTimeOffset _fetchedAtUtc = DateTimeOffset.MinValue;

    public async Task<string?> GetPemAsync(long keyId, CancellationToken cancellationToken = default)
    {
        var settings = options.Value;
        var now = timeProvider.GetUtcNow();

        var stale = now - _fetchedAtUtc >= TimeSpan.FromHours(settings.KeyCacheHours);
        var unknown = !_keys.ContainsKey(keyId) && now - _fetchedAtUtc >= TimeSpan.FromSeconds(settings.MinRefreshIntervalSeconds);

        if (stale || unknown)
        {
            await RefreshAsync(settings.VerifierKeysUrl, cancellationToken);
        }

        return _keys.TryGetValue(keyId, out var pem) ? pem : null;
    }

    public void Dispose() => _refreshLock.Dispose();

    private async Task RefreshAsync(Uri url, CancellationToken cancellationToken)
    {
        await _refreshLock.WaitAsync(cancellationToken);
        try
        {
            var client = httpClientFactory.CreateClient(HttpClientName);
            var document = await client.GetFromJsonAsync<VerifierKeysDocument>(url, cancellationToken);

            if (document?.Keys is { Count: > 0 } keys)
            {
                // GroupBy, not ToDictionary on the raw list: a duplicated key id in Google's answer must not throw.
                _keys = keys
                    .Where(k => !string.IsNullOrWhiteSpace(k.Pem))
                    .GroupBy(k => k.KeyId)
                    .ToDictionary(g => g.Key, g => g.Last().Pem!);
            }

            // Stamp even an empty answer so a failing endpoint is retried at the throttled pace, not on every call.
            _fetchedAtUtc = timeProvider.GetUtcNow();
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or System.Text.Json.JsonException)
        {
            _fetchedAtUtc = timeProvider.GetUtcNow();
            LogRefreshFailed(logger, url.ToString(), ex);
        }
        finally
        {
            _refreshLock.Release();
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not refresh AdMob SSV keys from {Url}; keeping the previous set")]
    private static partial void LogRefreshFailed(ILogger logger, string url, Exception exception);

    private sealed record VerifierKeysDocument([property: JsonPropertyName("keys")] IReadOnlyList<VerifierKey>? Keys);

    private sealed record VerifierKey(
        [property: JsonPropertyName("keyId")] long KeyId,
        [property: JsonPropertyName("pem")] string? Pem);

    internal static long? ParseKeyId(string? value) =>
        long.TryParse(value, NumberStyles.None, CultureInfo.InvariantCulture, out var id) ? id : null;
}
