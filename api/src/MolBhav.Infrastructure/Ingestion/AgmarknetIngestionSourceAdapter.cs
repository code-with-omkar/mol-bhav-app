using System.Globalization;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Domain.Pricing;

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
        var offset = 0;

        var httpClient = httpClientFactory.CreateClient(HttpClientName);
        httpClient.Timeout = TimeSpan.FromSeconds(opts.RequestTimeoutSeconds);

        LogFetchStarted(logger, request.SourceCode, request.AsOfDate);

        try
        {
            while (true)
            {
                var url = BuildUrl(opts.ApiKey, dateFilter, opts.PageSize, offset);
                AgmarknetResponse? response;

                try
                {
                    response = await httpClient.GetFromJsonAsync<AgmarknetResponse>(url, cancellationToken);
                }
                catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.Unauthorized)
                {
                    LogUnauthorized(logger, request.SourceCode);
                    return IngestionFetchResult.Failed("Agmarknet API key is invalid or unauthorised. Check Agmarknet:ApiKey.");
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
                    await Task.Delay(opts.ThrottleDelayMs, cancellationToken);
                }
            }
        }
        catch (OperationCanceledException)
        {
            LogCancelled(logger, request.SourceCode);
            return IngestionFetchResult.Failed("Agmarknet fetch was cancelled.");
        }

        LogFetchCompleted(logger, request.SourceCode, request.AsOfDate, allRecords.Count);
        return IngestionFetchResult.Success(allRecords);
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
            .Select(r => r with { RecordDate = request.AsOfDate })
            .ToList();

        LogMockUsed(logger, request.SourceCode, path, records.Count);
        return IngestionFetchResult.Success(records);
    }

    // -----------------------------------------------------------------------
    // Mapping
    // -----------------------------------------------------------------------

    private static IngestedPriceRecord? MapRecord(AgmarknetRecord raw, DateOnly fallbackDate, AgmarknetOptions opts)
    {
        // commodity → ProductCode, variety → VariantCode, market → LocationCode
        var productCode = Remap(ToCode(raw.Commodity), opts.CommodityCodeMap);
        if (string.IsNullOrEmpty(productCode))
        {
            return null;
        }

        var variantCode = ToCodeOrNull(raw.Variety);
        var locationCode = Remap(ToCode(raw.Market), opts.MarketCodeMap);
        if (string.IsNullOrEmpty(locationCode))
        {
            return null;
        }

        // Parse prices — all are string decimals from the API ("1000.00").
        if (!TryParseDecimal(raw.ModalPrice, out var modal))
        {
            return null; // modal_price is mandatory.
        }

        var min = ParsePositiveOrNull(raw.MinPrice);
        var max = ParsePositiveOrNull(raw.MaxPrice);
        var qty = ParsePositiveOrNull(raw.ArrivalQty);

        var recordDate = ParseArrivalDate(raw.ArrivalDate) ?? fallbackDate;

        return new IngestedPriceRecord(
            ProductCode: productCode,
            VariantCode: variantCode,
            LocationKind: LocationKind.Mandi, // Agmarknet is always mandis.
            LocationCode: locationCode,
            MinPrice: min,
            MaxPrice: max,
            ModalPrice: modal,
            ArrivalQuantity: qty,
            RecordDate: recordDate);
    }

    /// <summary>
    /// Converts a free-text Agmarknet field to a lowercase slug matching our CatalogCode/MarketCode format
    /// (e.g. "Onion" → "onion", "Red Onion (Large)" → "red-onion-large", "Azadpur Mandi" → "azadpur-mandi").
    /// Admins must use the same convention when creating products/mandis so codes resolve correctly.
    /// </summary>
    private static string ToCode(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        // Lowercase → collapse non-alphanumeric runs to a single hyphen → strip leading/trailing hyphens.
        var slug = SlugNonAlpha().Replace(value.Trim().ToLowerInvariant(), "-").Trim('-');
        return slug;
    }

    /// <summary>Applies an admin-configured override (slugged Agmarknet name → our code); unmapped values pass through unchanged.</summary>
    private static string Remap(string code, Dictionary<string, string> map) =>
        code.Length > 0 && map.TryGetValue(code, out var mapped) && !string.IsNullOrWhiteSpace(mapped) ? mapped.Trim() : code;

    private static string? ToCodeOrNull(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        // Agmarknet sometimes sends these generic variety labels — treat as no-variant.
        var trimmed = value.Trim();
        if (trimmed.Equals("faq", StringComparison.OrdinalIgnoreCase)
            || trimmed.Equals("unclassified", StringComparison.OrdinalIgnoreCase)
            || trimmed.Equals("other", StringComparison.OrdinalIgnoreCase)
            || trimmed.Equals("-", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        return ToCode(trimmed);
    }

    private static bool TryParseDecimal(string? value, out decimal result)
    {
        result = 0;
        return !string.IsNullOrWhiteSpace(value)
               && decimal.TryParse(value.Trim(), NumberStyles.Number, CultureInfo.InvariantCulture, out result);
    }

    private static decimal? ParsePositiveOrNull(string? value) =>
        TryParseDecimal(value, out var parsed) && parsed > 0 ? parsed : null;

    private static DateOnly? ParseArrivalDate(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        // Agmarknet returns "DD/MM/YYYY"; some responses use "DD-MM-YYYY".
        Span<string> formats = ["dd/MM/yyyy", "d/M/yyyy", "dd-MM-yyyy", "d-M-yyyy"];
        foreach (var fmt in formats)
        {
            if (DateOnly.TryParseExact(value.Trim(), fmt, CultureInfo.InvariantCulture, DateTimeStyles.None, out var date))
            {
                return date;
            }
        }

        return null;
    }

    // -----------------------------------------------------------------------
    // URL building
    // -----------------------------------------------------------------------

    private static string BuildUrl(string apiKey, string dateFilter, int limit, int offset)
    {
        // date filter value contains "/" which must be encoded.
        var encodedDate = Uri.EscapeDataString(dateFilter);
        return $"/resource/{ResourceId}?api-key={Uri.EscapeDataString(apiKey)}&format=json&limit={limit}&offset={offset}&filters%5Barrival_date%5D={encodedDate}";
    }

    // -----------------------------------------------------------------------
    // Compiled regex
    // -----------------------------------------------------------------------

    [GeneratedRegex(@"[^a-z0-9]+")]
    private static partial Regex SlugNonAlpha();

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

    [LoggerMessage(Level = LogLevel.Error, Message = "[Agmarknet] HTTP error for source {SourceCode}")]
    private static partial void LogHttpError(ILogger logger, string sourceCode, Exception exception);

    [LoggerMessage(Level = LogLevel.Error, Message = "[Agmarknet] Unexpected error for source {SourceCode}")]
    private static partial void LogUnexpectedError(ILogger logger, string sourceCode, Exception exception);

    [LoggerMessage(Level = LogLevel.Warning, Message = "[Agmarknet] Bad response for source {SourceCode}: {Message}")]
    private static partial void LogBadResponse(ILogger logger, string sourceCode, string message);

    [LoggerMessage(Level = LogLevel.Debug, Message = "[Agmarknet] Page fetched for {SourceCode}: offset={Offset}, count={Count}, total={Total}")]
    private static partial void LogPageFetched(ILogger logger, string sourceCode, int offset, int count, int total);

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

        [JsonPropertyName("total")]
        public int Total { get; set; }

        [JsonPropertyName("count")]
        public int Count { get; set; }

        [JsonPropertyName("offset")]
        public int Offset { get; set; }

        [JsonPropertyName("limit")]
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

        [JsonPropertyName("min_price")]
        public string? MinPrice { get; set; }

        [JsonPropertyName("max_price")]
        public string? MaxPrice { get; set; }

        [JsonPropertyName("modal_price")]
        public string? ModalPrice { get; set; }

        [JsonPropertyName("arrival_qty")]
        public string? ArrivalQty { get; set; }
    }
}
