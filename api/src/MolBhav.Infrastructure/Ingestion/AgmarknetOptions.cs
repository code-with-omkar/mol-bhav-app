namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Configuration for the Agmarknet/data.gov.in ingestion adapter (BRD §9, resource 9ef84268-d588-465a-a308-a864a43d0070).
/// <c>ApiKey</c> must be supplied via user-secrets or environment — never appsettings plain text.
/// </summary>
public sealed class AgmarknetOptions
{
    public const string SectionName = "Agmarknet";

    /// <summary>API key from https://api.data.gov.in — set via user-secrets or environment variable <c>Agmarknet__ApiKey</c>.</summary>
    public string ApiKey { get; set; } = string.Empty;

    /// <summary>Records per paginated request (max 500 per data.gov.in quota).</summary>
    public int PageSize { get; set; } = 500;

    /// <summary>Milliseconds to wait between paginated requests to avoid hitting rate limits.</summary>
    public int ThrottleDelayMs { get; set; } = 250;

    /// <summary>HTTP request timeout per page call.</summary>
    public int RequestTimeoutSeconds { get; set; } = 30;

    /// <summary>Slugged Agmarknet <c>market</c> → our mandi code, for mandis whose code differs (e.g. <c>"pune": "apmc-pune"</c>). Keys are case-insensitive.</summary>
    public Dictionary<string, string> MarketCodeMap { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>Slugged Agmarknet <c>commodity</c> → our product code (e.g. <c>"soyabean": "soybean"</c>). Keys are case-insensitive.</summary>
    public Dictionary<string, string> CommodityCodeMap { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>Development only (startup fails elsewhere): serve <see cref="MockDataPath"/> instead of calling data.gov.in.</summary>
    public bool UseMockData { get; set; }

    /// <summary>Fixture in data.gov.in response shape; relative paths resolve against the app's output directory.</summary>
    public string MockDataPath { get; set; } = "SampleData/agmarknet-sample.json";
}
