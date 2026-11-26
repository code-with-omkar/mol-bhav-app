namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Configuration for the Agmarknet/data.gov.in ingestion adapter (BRD §9, resource 9ef84268-d588-465a-a308-a864a43d0070).
/// <c>ApiKey</c> must be supplied via user-secrets or environment — never appsettings plain text.
/// </summary>
/// <remarks>
/// The feed is slow and sometimes down (503 "No server is available", 500, stalls), and that cannot be fixed on our side.
/// What can be bounded is how long a bad day takes, so every wait below has its own limit: opening the connection, one
/// attempt, one page with its retries, and the whole run. A run that sees the server failing stops early (circuit
/// breaker) and the scheduler tries again later.
/// </remarks>
public sealed class AgmarknetOptions
{
    public const string SectionName = "Agmarknet";

    /// <summary>API key from https://api.data.gov.in — set via user-secrets or environment variable <c>Agmarknet__ApiKey</c>.</summary>
    public string ApiKey { get; set; } = string.Empty;

    /// <summary>Records per paginated request (max 500 per data.gov.in quota).</summary>
    public int PageSize { get; set; } = 500;

    /// <summary>Milliseconds to wait between paginated requests to avoid hitting rate limits.</summary>
    public int ThrottleDelayMs { get; set; } = 250;

    /// <summary>How long opening the connection may take before that attempt fails (and is retried).</summary>
    public int ConnectTimeoutSeconds { get; set; } = 8;

    /// <summary>One request, from sending to the last byte of the answer. A healthy page returns in a few seconds.</summary>
    public double AttemptTimeoutSeconds { get; set; } = 40;

    /// <summary>One page including all its retries and waits; the page fails when this runs out.</summary>
    public double RequestTimeoutSeconds { get; set; } = 100;

    /// <summary>The whole run (every page of every pass). When it runs out the run stops and the next scheduled run tries again.</summary>
    public double RunBudgetSeconds { get; set; } = 240;

    /// <summary>How many times one page is retried after a transient failure (408, 429, 502, 503, 504, a stall or a dropped connection). A 500 is retried once. 0 disables retries.</summary>
    public int MaxRetries { get; set; } = 3;

    /// <summary>First retry waits about this long (with jitter), doubling each time — unless the server sends <c>Retry-After</c>, which is used instead.</summary>
    public double RetryBaseDelaySeconds { get; set; } = 3;

    /// <summary>Upper bound on the exponential wait between retries.</summary>
    public double MaxRetryDelaySeconds { get; set; } = 30;

    /// <summary>A <c>Retry-After</c> longer than this is not waited out: the page fails and the next scheduled run tries again.</summary>
    public double MaxRetryAfterSeconds { get; set; } = 60;

    /// <summary>The circuit breaker looks at attempts in this window.</summary>
    public double BreakerSamplingSeconds { get; set; } = 90;

    /// <summary>It cannot open before this many attempts were made in the window.</summary>
    public int BreakerMinimumThroughput { get; set; } = 4;

    /// <summary>It opens when this share of the attempts in the window failed (0–1). An open breaker ends the run as "unavailable".</summary>
    public double BreakerFailureRatio { get; set; } = 0.6;

    /// <summary>How long the breaker stays open (it only matters within a run; each run starts closed).</summary>
    public double BreakerBreakSeconds { get; set; } = 45;

    /// <summary>A full pull adds feed markets the catalog lacks (with districts and states) before matching prices.</summary>
    public bool AutoAddMarkets { get; set; } = true;

    /// <summary>A full pull adds feed commodities the catalog lacks as hidden products, for an admin to review.</summary>
    public bool AutoAddCommodities { get; set; } = true;

    /// <summary>Sub-category code new commodities are filed under.</summary>
    public string AutoAddSubCategoryCode { get; set; } = "other-produce";

    /// <summary>Unit code new commodities are priced in (the feed quotes rupees per quintal).</summary>
    public string AutoAddUnitCode { get; set; } = "quintal";

    /// <summary>Slugged Agmarknet <c>market</c> → our mandi code, for mandis whose code differs (e.g. <c>"pune": "apmc-pune"</c>). Keys are case-insensitive.</summary>
    public Dictionary<string, string> MarketCodeMap { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>Slugged Agmarknet <c>commodity</c> → our product code (e.g. <c>"soyabean": "soybean"</c>). Keys are case-insensitive.</summary>
    public Dictionary<string, string> CommodityCodeMap { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>Feed state name → catalog state name, where the feed spells it differently (e.g. <c>"Keralam": "Kerala"</c>), so no second state is created.</summary>
    public Dictionary<string, string> StateNameMap { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary><c>"Catalog state/Feed district"</c> → catalog district name (e.g. <c>"Kerala/Palakad": "Palakkad"</c>).</summary>
    public Dictionary<string, string> DistrictNameMap { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>Development only (startup fails elsewhere): serve <see cref="MockDataPath"/> instead of calling data.gov.in.</summary>
    public bool UseMockData { get; set; }

    /// <summary>Fixture in data.gov.in response shape; relative paths resolve against the app's output directory.</summary>
    public string MockDataPath { get; set; } = "SampleData/agmarknet-sample.json";
}
