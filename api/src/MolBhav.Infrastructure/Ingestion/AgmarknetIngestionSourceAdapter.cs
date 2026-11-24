using System.Globalization;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Http.Resilience;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Domain.Ingestion;
using Polly;
using Polly.CircuitBreaker;
using Polly.Retry;
using Polly.Timeout;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Agmarknet/data.gov.in ingestion adapter (BRD §9): fetches daily mandi price arrivals for a given date,
/// paginates until all records are consumed, normalises raw field values to the slug-style codes the admin portal
/// uses for <c>Product.Code</c> and <c>Mandi.Code</c>, and returns a list of <see cref="IngestedPriceRecord"/>
/// for the command handler to resolve and persist. All locations from Agmarknet are mandis.
/// </summary>
internal sealed partial class AgmarknetIngestionSourceAdapter(
    IHttpClientFactory httpClientFactory,
    IOptions<AgmarknetOptions> options,
    ILogger<AgmarknetIngestionSourceAdapter> logger) : IIngestionSourceAdapter
{
    public const string SourceCode = "agmarknet";
    public const string HttpClientName = "agmarknet";
    public const string BaseAddress = "https://api.data.gov.in";
    private const string ResourceId = "9ef84268-d588-465a-a308-a864a43d0070";

    public async Task<IngestionFetchResult> FetchAsync(IngestionFetchRequest request, CancellationToken cancellationToken = default)
    {
        var opts = options.Value;

        if (opts.UseMockData)
        {
            return await FetchMockAsync(request, opts, cancellationToken);
        }

        if (string.IsNullOrWhiteSpace(opts.ApiKey))
        {
            LogMissingApiKey(logger);
            return IngestionFetchResult.Failed("Agmarknet:ApiKey is not configured. Set it via user-secrets or the Agmarknet__ApiKey environment variable.");
        }

        // Agmarknet stores arrival_date as "DD/MM/YYYY" — filter must match that exact format.
        var dateFilter = request.AsOfDate.ToString("dd/MM/yyyy", CultureInfo.InvariantCulture);

        var allRecords = new List<IngestedPriceRecord>();

        var httpClient = httpClientFactory.CreateClient(HttpClientName);
        // HttpClient.Timeout is one client-wide timer that would cut across the layered timeouts below; they own the limits.
        httpClient.Timeout = Timeout.InfiniteTimeSpan;

        // One pipeline per run, so its circuit breaker starts closed and judges only this run's requests.
        var pipeline = BuildPipeline(opts, request.SourceCode);

        // The whole run is bounded too: a slow day ends the run, and the scheduler tries again later.
        using var runBudget = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        runBudget.CancelAfter(TimeSpan.FromSeconds(opts.RunBudgetSeconds));
        var runToken = runBudget.Token;

        LogFetchStarted(logger, request.SourceCode, request.AsOfDate);

        // The source's schedule filter: an empty list is "all", otherwise one pass per state × commodity × market
        // (data.gov.in filters server-side on exact names). No filter = the whole feed in one pass.
        var filter = request.Filter ?? IngestionFilter.Empty;
        var passes = (
            from state in OrAll(filter.States)
            from commodity in OrAll(filter.Commodities)
            from market in OrAll(filter.Markets)
            select (state, commodity, market)).ToList();

        // A full pull sees every row, so it can tell the app which names exist (for the filter dropdowns).
        var commoditiesSeen = filter.IsEmpty ? new HashSet<string>(StringComparer.OrdinalIgnoreCase) : null;
        var marketsSeen = filter.IsEmpty ? new HashSet<FeedMarket>() : null;

        try
        {
            foreach (var (state, commodity, market) in passes)
            {
                var offset = 0;
                while (true)
                {
                    var url = BuildUrl(opts.ApiKey, dateFilter, state, commodity, market, opts.PageSize, offset);
                    AgmarknetResponse? response;

                    try
                    {
                        response = await GetPageAsync(httpClient, pipeline, url, opts, runToken);
                    }
                    catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.Unauthorized)
                    {
                        LogUnauthorized(logger, request.SourceCode);
                        return IngestionFetchResult.Failed("Agmarknet API key is invalid or unauthorised. Check Agmarknet:ApiKey.");
                    }
                    catch (BrokenCircuitException)
                    {
                        // Several attempts in a row failed: the server is down. Stop now instead of trying every remaining pass.
                        LogCircuitOpen(logger, request.SourceCode);
                        return IngestionFetchResult.Failed(
                            "Agmarknet looks unavailable (several requests failed in a row), so this run stopped early. It will try again at the next scheduled run.");
                    }
                    catch (HttpRequestException ex)
                    {
                        LogHttpError(logger, request.SourceCode, ex);
                        return IngestionFetchResult.Failed($"Agmarknet HTTP error: {ex.Message}");
                    }
                    catch (Exception ex) when (ex is not OperationCanceledException)
                    {
                        LogUnexpectedError(logger, request.SourceCode, ex);
                        return IngestionFetchResult.Failed($"Agmarknet fetch failed unexpectedly: {ex.Message}");
                    }

                    if (response is null || !string.Equals(response.Status, "ok", StringComparison.OrdinalIgnoreCase))
                    {
                        var msg = response?.Message ?? "Empty or non-ok response";
                        LogBadResponse(logger, request.SourceCode, msg);
                        return IngestionFetchResult.Failed($"Agmarknet returned a non-ok response: {msg}");
                    }

                    if (response.Records is null || response.Records.Count == 0)
                    {
                        break; // No more pages.
                    }

                    foreach (var raw in response.Records)
                    {
                        if (marketsSeen is not null && !string.IsNullOrWhiteSpace(raw.Market) && !string.IsNullOrWhiteSpace(raw.State))
                        {
                            marketsSeen.Add(new FeedMarket(raw.Market.Trim(), raw.State.Trim(), raw.District?.Trim() ?? string.Empty));
                        }

                        if (commoditiesSeen is not null && !string.IsNullOrWhiteSpace(raw.Commodity))
                        {
                            commoditiesSeen.Add(raw.Commodity.Trim());
                        }

                        var record = MapRecord(raw, request.AsOfDate, opts);
                        if (record is not null)
                        {
                            allRecords.Add(record);
                        }
                    }

                    LogPageFetched(logger, request.SourceCode, offset, response.Records.Count, response.Total);

                    // Advance or stop.
                    offset += response.Records.Count;
                    if (response.Records.Count < opts.PageSize || offset >= response.Total)
                    {
                        break;
                    }

                    // Polite throttle between pages.
                    if (opts.ThrottleDelayMs > 0)
                    {
                        await Task.Delay(opts.ThrottleDelayMs, runToken);
                    }
                }
            }
        }
        catch (OperationCanceledException) when (runBudget.IsCancellationRequested && !cancellationToken.IsCancellationRequested)
        {
            LogRunBudgetElapsed(logger, request.SourceCode, opts.RunBudgetSeconds);
            return IngestionFetchResult.Failed(
                $"Agmarknet was too slow: the run stopped after {TimeSpan.FromSeconds(opts.RunBudgetSeconds).TotalMinutes:0.#} minutes. It will try again at the next scheduled run.");
        }
        catch (OperationCanceledException)
        {
            LogCancelled(logger, request.SourceCode);
            return IngestionFetchResult.Failed("Agmarknet fetch was cancelled.");
        }

        LogFetchCompleted(logger, request.SourceCode, request.AsOfDate, allRecords.Count);
        return IngestionFetchResult.Success(
            allRecords,
            marketsSeen is null || commoditiesSeen is null ? null : new FeedNames([.. commoditiesSeen], [.. marketsSeen]));
    }

    /// <summary>
    /// Development-only (enforced in DI): reads a fixture in the exact data.gov.in response shape and runs it through
    /// the same mapping as live data. Rows are re-dated to <see cref="IngestionFetchRequest.AsOfDate"/> so each day's run
    /// produces fresh records; a second run on the same day surfaces as duplicate errors, same as live.
    /// </summary>
    private async Task<IngestionFetchResult> FetchMockAsync(IngestionFetchRequest request, AgmarknetOptions opts, CancellationToken cancellationToken)
    {
        var path = Path.IsPathRooted(opts.MockDataPath)
            ? opts.MockDataPath
            : Path.Combine(AppContext.BaseDirectory, opts.MockDataPath);

        if (!File.Exists(path))
        {
            return IngestionFetchResult.Failed($"Agmarknet mock data file not found at '{path}'.");
        }

        AgmarknetResponse? response;
        try
        {
            await using var stream = File.OpenRead(path);
            response = await JsonSerializer.DeserializeAsync<AgmarknetResponse>(stream, cancellationToken: cancellationToken);
        }
        catch (JsonException ex)
        {
            return IngestionFetchResult.Failed($"Agmarknet mock data file is not valid JSON: {ex.Message}");
        }

        var records = (response?.Records ?? [])
            .Select(raw => MapRecord(raw, request.AsOfDate, opts))
            .OfType<IngestedPriceRecord>()
            .Select(r => VaryForDay(r with { RecordDate = request.AsOfDate }))
            .ToList();

        LogMockUsed(logger, request.SourceCode, path, records.Count);
        return IngestionFetchResult.Success(records);
    }

    /// <summary>
    /// Mock prices move from day to day (deterministically, −12%…+12% per product and location) so alerts, trends and
    /// "unchanged" counts can be exercised in Development. The same day always yields the same figures, so re-running a
    /// day stays idempotent. Never used outside mock mode.
    /// </summary>
    internal static IngestedPriceRecord VaryForDay(IngestedPriceRecord price)
    {
        var key = $"{price.ProductCode}|{price.VariantCode}|{price.LocationCode}|{price.RecordDate.DayNumber}";
        var hash = 17u;
        foreach (var c in key)
        {
            hash = unchecked((hash * 31u) + c);
        }

        var factor = 1m + (((int)(hash % 25u) - 12) / 100m);

        decimal Scale(decimal value) => decimal.Round(value * factor, 0, MidpointRounding.AwayFromZero);

        return price with
        {
            MinPrice = price.MinPrice is { } min ? Scale(min) : null,
            MaxPrice = price.MaxPrice is { } max ? Scale(max) : null,
            ModalPrice = Scale(price.ModalPrice),
        };
    }

    // -----------------------------------------------------------------------
    // Mapping
    // -----------------------------------------------------------------------

    private static IngestedPriceRecord? MapRecord(AgmarknetRecord raw, DateOnly fallbackDate, AgmarknetOptions opts) =>
        // API rows that cannot be mapped are skipped (the request is already filtered to one date); uploads report them.
        AgmarknetRowMapper.Map(
            raw.Commodity, raw.Variety, raw.Market, raw.MinPrice, raw.MaxPrice, raw.ModalPrice, raw.ArrivalQty,
            raw.ArrivalDate, fallbackDate, opts, out _);

    // -----------------------------------------------------------------------
    // HTTP with timeouts, retries and a circuit breaker
    // -----------------------------------------------------------------------

    /// <summary>
    /// One page through the run's resilience pipeline. Layers, outermost first: a total limit for the page, retries with
    /// jittered backoff, a circuit breaker, and a limit for each single attempt. Anything still failing after the retries
    /// throws <see cref="HttpRequestException"/> with its status (a 401 is never retried), which the caller turns into a
    /// failed run; an open breaker throws <see cref="BrokenCircuitException"/>.
    /// </summary>
    private static async Task<AgmarknetResponse?> GetPageAsync(
        HttpClient httpClient,
        ResiliencePipeline<HttpResponseMessage> pipeline,
        string url,
        AgmarknetOptions opts,
        CancellationToken cancellationToken)
    {
        HttpResponseMessage message;
        try
        {
            message = await pipeline.ExecuteAsync(
                async ct => await SendAsync(httpClient, url, ct),
                cancellationToken);
        }
        catch (TimeoutRejectedException ex)
        {
            throw new HttpRequestException(
                $"The request timed out (limit {opts.AttemptTimeoutSeconds:0.#}s per attempt, {opts.RequestTimeoutSeconds:0.#}s per page).",
                ex,
                HttpStatusCode.RequestTimeout);
        }

        using (message)
        {
            message.EnsureSuccessStatusCode();
            return await message.Content.ReadFromJsonAsync<AgmarknetResponse>(cancellationToken);
        }
    }

    /// <summary>One attempt. The answer is read in full here, so the attempt limit also covers a slow body.</summary>
    private static async Task<HttpResponseMessage> SendAsync(HttpClient httpClient, string url, CancellationToken cancellationToken)
    {
        var response = await httpClient.GetAsync(url, cancellationToken);

        // A gateway error page that arrives as "200 OK" HTML is a server problem, not data: treat it as a 503 so it is retried.
        if (response.IsSuccessStatusCode
            && response.Content.Headers.ContentType?.MediaType?.Contains("html", StringComparison.OrdinalIgnoreCase) == true)
        {
            response.Dispose();
            return new HttpResponseMessage(HttpStatusCode.ServiceUnavailable);
        }

        return response;
    }

    private ResiliencePipeline<HttpResponseMessage> BuildPipeline(AgmarknetOptions opts, string sourceCode)
    {
        var builder = new ResiliencePipelineBuilder<HttpResponseMessage>()
            .AddTimeout(TimeSpan.FromSeconds(opts.RequestTimeoutSeconds));

        if (opts.MaxRetries > 0)
        {
            var retry = new HttpRetryStrategyOptions
            {
                MaxRetryAttempts = opts.MaxRetries,
                BackoffType = DelayBackoffType.Exponential,
                UseJitter = true,
                Delay = TimeSpan.FromSeconds(opts.RetryBaseDelaySeconds),
                ShouldRetryAfterHeader = true,
                ShouldHandle = args => ValueTask.FromResult(ShouldRetry(args.Outcome, args.AttemptNumber, opts)),
                OnRetry = args =>
                {
                    if (args.Outcome.Result is { } failed)
                    {
                        LogRetrying(logger, sourceCode, (int)failed.StatusCode, args.AttemptNumber + 1, opts.MaxRetries, args.RetryDelay.TotalSeconds);
                    }
                    else
                    {
                        var timedOut = args.Outcome.Exception is TimeoutRejectedException;
                        LogRetryingAfterFailure(logger, sourceCode, timedOut ? "timed out" : "connection failed", args.AttemptNumber + 1, opts.MaxRetries, args.RetryDelay.TotalSeconds);
                    }

                    args.Outcome.Result?.Dispose();
                    return default;
                },
            };

            if (opts.MaxRetryDelaySeconds > 0)
            {
                retry.MaxDelay = TimeSpan.FromSeconds(opts.MaxRetryDelaySeconds);
            }

            builder.AddRetry(retry);
        }

        return builder
            .AddCircuitBreaker(new HttpCircuitBreakerStrategyOptions
            {
                SamplingDuration = TimeSpan.FromSeconds(opts.BreakerSamplingSeconds),
                MinimumThroughput = opts.BreakerMinimumThroughput,
                FailureRatio = opts.BreakerFailureRatio,
                BreakDuration = TimeSpan.FromSeconds(opts.BreakerBreakSeconds),
            })
            .AddTimeout(TimeSpan.FromSeconds(opts.AttemptTimeoutSeconds))
            .Build();
    }

    /// <summary>
    /// What is worth another try: a throttled or briefly unavailable server (408, 429, 502, 503, 504), a stalled or dropped
    /// request, and a 500 once (often it is a real error, sometimes overload). Not a rejected key, and not a
    /// <c>Retry-After</c> longer than <see cref="AgmarknetOptions.MaxRetryAfterSeconds"/>: that is left to the next scheduled run.
    /// </summary>
    private static bool ShouldRetry(Outcome<HttpResponseMessage> outcome, int attemptNumber, AgmarknetOptions opts)
    {
        if (outcome.Exception is HttpRequestException or TimeoutRejectedException)
        {
            return true;
        }

        if (outcome.Exception is not null || outcome.Result is not { } response)
        {
            return false;
        }

        var retryable = response.StatusCode is HttpStatusCode.RequestTimeout or HttpStatusCode.TooManyRequests
            or HttpStatusCode.BadGateway or HttpStatusCode.ServiceUnavailable or HttpStatusCode.GatewayTimeout
            || (response.StatusCode == HttpStatusCode.InternalServerError && attemptNumber == 0);
        if (!retryable)
        {
            return false;
        }

        var retryAfter = response.Headers.RetryAfter;
        var requested = retryAfter?.Delta
            ?? (retryAfter?.Date is { } date ? date - DateTimeOffset.UtcNow : (TimeSpan?)null);
        return requested is not { } wait || wait <= TimeSpan.FromSeconds(opts.MaxRetryAfterSeconds);
    }

    // -----------------------------------------------------------------------
    // URL building
    // -----------------------------------------------------------------------

    /// <summary>An empty filter list means "all": one pass with no constraint (<c>null</c>).</summary>
    private static IEnumerable<string?> OrAll(IReadOnlyList<string> names) => names.Count == 0 ? [null] : names;

    private static string BuildUrl(string apiKey, string dateFilter, string? state, string? commodity, string? market, int limit, int offset)
    {
        // date filter value contains "/" which must be encoded.
        var encodedDate = Uri.EscapeDataString(dateFilter);
        var url = $"/resource/{ResourceId}?api-key={Uri.EscapeDataString(apiKey)}&format=json&limit={limit}&offset={offset}&filters%5Barrival_date%5D={encodedDate}";
        if (state is not null)
        {
            url += $"&filters%5Bstate.keyword%5D={Uri.EscapeDataString(state)}";
        }

        if (commodity is not null)
        {
            url += $"&filters%5Bcommodity%5D={Uri.EscapeDataString(commodity)}";
        }

        if (market is not null)
        {
            url += $"&filters%5Bmarket%5D={Uri.EscapeDataString(market)}";
        }

        return url;
    }

    // -----------------------------------------------------------------------
    // Compiled regex
    // -----------------------------------------------------------------------


    // -----------------------------------------------------------------------
    // Structured logging
    // -----------------------------------------------------------------------

    [LoggerMessage(Level = LogLevel.Warning, Message = "[Agmarknet MOCK] Source {SourceCode} served from fixture {Path}: {RecordCount} records — not live data")]
    private static partial void LogMockUsed(ILogger logger, string sourceCode, string path, int recordCount);

    [LoggerMessage(Level = LogLevel.Warning, Message = "[Agmarknet] ApiKey is not configured — skipping adapter")]
    private static partial void LogMissingApiKey(ILogger logger);

    [LoggerMessage(Level = LogLevel.Information, Message = "[Agmarknet] Starting fetch for source {SourceCode}, date {AsOfDate}")]
    private static partial void LogFetchStarted(ILogger logger, string sourceCode, DateOnly asOfDate);

    [LoggerMessage(Level = LogLevel.Warning, Message = "[Agmarknet] Unauthorised response for source {SourceCode} — check ApiKey")]
    private static partial void LogUnauthorized(ILogger logger, string sourceCode);

    [LoggerMessage(Level = LogLevel.Warning, Message = "[Agmarknet] Source {SourceCode} answered HTTP {Status}; retry {Attempt}/{MaxRetries} in {DelaySeconds:F0}s")]
    private static partial void LogRetrying(ILogger logger, string sourceCode, int status, int attempt, int maxRetries, double delaySeconds);

    [LoggerMessage(Level = LogLevel.Warning, Message = "[Agmarknet] Source {SourceCode} request {Problem}; retry {Attempt}/{MaxRetries} in {DelaySeconds:F0}s")]
    private static partial void LogRetryingAfterFailure(ILogger logger, string sourceCode, string problem, int attempt, int maxRetries, double delaySeconds);

    [LoggerMessage(Level = LogLevel.Error, Message = "[Agmarknet] HTTP error for source {SourceCode}")]
    private static partial void LogHttpError(ILogger logger, string sourceCode, Exception exception);

    [LoggerMessage(Level = LogLevel.Error, Message = "[Agmarknet] Unexpected error for source {SourceCode}")]
    private static partial void LogUnexpectedError(ILogger logger, string sourceCode, Exception exception);

    [LoggerMessage(Level = LogLevel.Warning, Message = "[Agmarknet] Bad response for source {SourceCode}: {Message}")]
    private static partial void LogBadResponse(ILogger logger, string sourceCode, string message);

    [LoggerMessage(Level = LogLevel.Debug, Message = "[Agmarknet] Page fetched for {SourceCode}: offset={Offset}, count={Count}, total={Total}")]
    private static partial void LogPageFetched(ILogger logger, string sourceCode, int offset, int count, int total);

    [LoggerMessage(Level = LogLevel.Warning, Message = "[Agmarknet] Circuit breaker open for source {SourceCode}: the server keeps failing, stopping the run early")]
    private static partial void LogCircuitOpen(ILogger logger, string sourceCode);

    [LoggerMessage(Level = LogLevel.Warning, Message = "[Agmarknet] Run budget of {BudgetSeconds:F0}s elapsed for source {SourceCode}, stopping the run")]
    private static partial void LogRunBudgetElapsedCore(ILogger logger, double budgetSeconds, string sourceCode);

    private static void LogRunBudgetElapsed(ILogger logger, string sourceCode, double budgetSeconds) =>
        LogRunBudgetElapsedCore(logger, budgetSeconds, sourceCode);

    [LoggerMessage(Level = LogLevel.Warning, Message = "[Agmarknet] Fetch cancelled for source {SourceCode}")]
    private static partial void LogCancelled(ILogger logger, string sourceCode);

    [LoggerMessage(Level = LogLevel.Information, Message = "[Agmarknet] Completed fetch for {SourceCode}, date {AsOfDate}: {RecordCount} records")]
    private static partial void LogFetchCompleted(ILogger logger, string sourceCode, DateOnly asOfDate, int recordCount);

    // -----------------------------------------------------------------------
    // JSON response models — private to this adapter
    // -----------------------------------------------------------------------

    private sealed class AgmarknetResponse
    {
        [JsonPropertyName("status")]
        public string Status { get; set; } = string.Empty;

        [JsonPropertyName("message")]
        public string? Message { get; set; }

        // The live API sends total/count as numbers but limit/offset as strings ("500"); accept both.
        [JsonPropertyName("total")]
        [JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)]
        public int Total { get; set; }

        [JsonPropertyName("count")]
        [JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)]
        public int Count { get; set; }

        [JsonPropertyName("offset")]
        [JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)]
        public int Offset { get; set; }

        [JsonPropertyName("limit")]
        [JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)]
        public int Limit { get; set; }

        [JsonPropertyName("records")]
        public List<AgmarknetRecord>? Records { get; set; }
    }

    private sealed class AgmarknetRecord
    {
        [JsonPropertyName("state")]
        public string State { get; set; } = string.Empty;

        [JsonPropertyName("district")]
        public string District { get; set; } = string.Empty;

        [JsonPropertyName("market")]
        public string Market { get; set; } = string.Empty;

        [JsonPropertyName("commodity")]
        public string Commodity { get; set; } = string.Empty;

        [JsonPropertyName("variety")]
        public string Variety { get; set; } = string.Empty;

        [JsonPropertyName("grade")]
        public string? Grade { get; set; }

        [JsonPropertyName("arrival_date")]
        public string ArrivalDate { get; set; } = string.Empty;

        // Prices arrive as JSON numbers in the live API and as strings in older exports/fixtures.
        [JsonPropertyName("min_price")]
        [JsonConverter(typeof(StringOrNumberConverter))]
        public string? MinPrice { get; set; }

        [JsonPropertyName("max_price")]
        [JsonConverter(typeof(StringOrNumberConverter))]
        public string? MaxPrice { get; set; }

        [JsonPropertyName("modal_price")]
        [JsonConverter(typeof(StringOrNumberConverter))]
        public string? ModalPrice { get; set; }

        [JsonPropertyName("arrival_qty")]
        [JsonConverter(typeof(StringOrNumberConverter))]
        public string? ArrivalQty { get; set; }
    }

    /// <summary>Reads a JSON string or number as its text (so <c>5000</c> and <c>"5000"</c> both give "5000").</summary>
    internal sealed class StringOrNumberConverter : JsonConverter<string?>
    {
        public override string? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) => reader.TokenType switch
        {
            JsonTokenType.String => reader.GetString(),
            JsonTokenType.Number => reader.TryGetDecimal(out var number)
                ? number.ToString(CultureInfo.InvariantCulture)
                : reader.GetDouble().ToString(CultureInfo.InvariantCulture),
            JsonTokenType.Null => null,
            _ => throw new JsonException($"Expected a string or number but found {reader.TokenType}."),
        };

        public override void Write(Utf8JsonWriter writer, string? value, JsonSerializerOptions options) => writer.WriteStringValue(value);
    }
}
