#:package Npgsql@9.0.3
#:property PublishAot=false

// Loads past mandi prices from data.gov.in's "Variety-wise Daily Market Prices" dataset into the MolBhav database.
// One market day is one batch: it is fetched, matched to the catalog with the same code rules as the daily pull,
// bulk-copied in one statement and then written to the progress file, so a stopped run resumes where it was.
// Rows are inserted directly, so no alerts are raised for old prices. Rows already stored are never duplicated.
//
//   MB_CS=<connection string>  MB_KEY=<data.gov.in api key>
//   dotnet run tools/history-import.cs -- <from yyyy-MM-dd> <to yyyy-MM-dd> <progress file> <appsettings.json>
//
// Days are loaded newest first. Delete a line from the progress file to load that day again.

using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;
using Npgsql;
using NpgsqlTypes;

const string Resource = "35985678-0d79-46b4-9ed6-6f13308a1d24";
const int PageSize = 10_000;

var from = DateOnly.ParseExact(args[0], "yyyy-MM-dd", CultureInfo.InvariantCulture);
var to = DateOnly.ParseExact(args[1], "yyyy-MM-dd", CultureInfo.InvariantCulture);
var progressFile = args[2];
var settingsFile = args[3];
var key = Environment.GetEnvironmentVariable("MB_KEY") ?? throw new InvalidOperationException("MB_KEY is not set.");
var connection = Environment.GetEnvironmentVariable("MB_CS") ?? throw new InvalidOperationException("MB_CS is not set.");

await using var db = NpgsqlDataSource.Create(connection);
using var http = new HttpClient { Timeout = TimeSpan.FromSeconds(90) };

var (marketMap, commodityMap, stateMap, districtMap) = ReadCodeMaps(settingsFile);
var sourceId = (Guid)(await Scalar("select id from pricing.price_sources where code = 'agmarknet'")
    ?? throw new InvalidOperationException("The agmarknet price source does not exist."));

var products = new Dictionary<string, (Guid Id, Guid Unit, decimal Factor)>(StringComparer.Ordinal);
// The feed quotes rupees per quintal; each price is stored per the product's own unit (per kg: a hundredth).
await foreach (var r in Query(
    "select p.code, p.id, p.default_unit_id, u.to_base_factor / q.to_base_factor from catalog.products p join catalog.units_of_measure u on u.id = p.default_unit_id join catalog.units_of_measure q on q.code = 'quintal' and q.dimension = u.dimension where p.is_active"))
    products[r.GetString(0)] = (r.GetGuid(1), r.GetGuid(2), r.GetDecimal(3));
var variants = new Dictionary<(Guid, string), Guid>();
await foreach (var r in Query("select product_id, code, id from catalog.product_variants where is_active"))
    variants[(r.GetGuid(0), r.GetString(1))] = r.GetGuid(2);
var mandis = new Dictionary<string, Guid>(StringComparer.Ordinal);
// Older years spell many markets differently ("Pune APMC" for "APMC Pune"). Such a row is matched when exactly one
// catalog mandi in the same state and district has the same name once the generic words are ignored.
var sameName = new Dictionary<(string State, string District, string Name), Guid?>();
await foreach (var r in Query(
    "select m.code, m.id, m.name, d.name, s.name from market.mandis m join market.districts d on d.id = m.district_id join market.states s on s.id = d.state_id where m.is_active"))
{
    mandis[r.GetString(0)] = r.GetGuid(1);
    var name = (r.GetString(4).ToLowerInvariant(), r.GetString(3).ToLowerInvariant(), NameKey(r.GetString(2)));
    if (name.Item3.Length > 0) sameName[name] = sameName.ContainsKey(name) ? null : r.GetGuid(1);
}

Console.WriteLine($"catalog: {products.Count} products, {variants.Count} variants, {mandis.Count} mandis");

// MB_COLLECT=1 loads no prices: it samples every 15th day for markets the catalog lacks and adds their names to the
// source's saved feed list, so "Add every market from the feed" can create them before the real load.
if (Environment.GetEnvironmentVariable("MB_COLLECT") == "1")
{
    var found = new Dictionary<string, Row>(StringComparer.Ordinal);
    var unknownProducts = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
    for (var day = to; day >= from; day = day.AddDays(-15))
    {
        try
        {
            foreach (var row in await FetchDay(day))
            {
                var code = MarketCodeFor(row);
                if (code.Length > 0 && !mandis.ContainsKey(code) && row.State.Length > 0 && row.District.Length > 0) found.TryAdd(code, row);
                if (!products.ContainsKey(Mapped(Slug(row.Commodity), commodityMap))) unknownProducts[row.Commodity] = unknownProducts.GetValueOrDefault(row.Commodity) + 1;
            }

            Console.WriteLine($"sampled {day:yyyy-MM-dd}: {found.Count} new markets so far");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"sample {day:yyyy-MM-dd} failed: {Safe(ex.Message)}");
        }
    }

    var json = "[" + string.Join(",", found.Values.Select(r =>
        $"{{\"Name\":\"{Escape(r.Market.Trim())}\",\"State\":\"{Escape(r.State.Trim())}\",\"District\":\"{Escape(r.District.Trim())}\"}}")) + "]";
    await using var update = db.CreateCommand("update ingestion.source_feed_options set markets = markets || $1 where price_source_id = $2");
    update.Parameters.Add(new NpgsqlParameter { Value = json, NpgsqlDbType = NpgsqlDbType.Jsonb });
    update.Parameters.AddWithValue(sourceId);
    Console.WriteLine($"added {found.Count} market names to the feed list ({await update.ExecuteNonQueryAsync()} row updated)");
    Console.WriteLine($"commodities not in the catalog: {unknownProducts.Count}");
    foreach (var (name, count) in unknownProducts.OrderByDescending(p => p.Value).Take(15)) Console.WriteLine($"  {name} ({count:N0} sampled rows)");
    return;
}

var done = File.Exists(progressFile)
    ? File.ReadLines(progressFile).Select(l => l.Split(' ')[0]).ToHashSet(StringComparer.Ordinal)
    : [];
var unknownMarkets = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
var failedDays = new List<DateOnly>();
long totalInserted = 0;
var started = DateTime.UtcNow;

for (var day = to; day >= from; day = day.AddDays(-1))
{
    var label = day.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
    if (done.Contains(label)) continue;

    try
    {
        var rows = await FetchDay(day);
        var counts = await Store(day, rows);
        totalInserted += counts.Inserted;
        var line = $"{label} fetched={rows.Count} inserted={counts.Inserted} existing={counts.Existing} unknown={counts.Unknown} invalid={counts.Invalid} duplicate={counts.Duplicate}";
        File.AppendAllText(progressFile, line + Environment.NewLine);
        Console.WriteLine($"{line} | total inserted {totalInserted:N0} in {(DateTime.UtcNow - started).TotalMinutes:N1} min");
    }
    catch (Exception ex)
    {
        // The day is not marked done, so the next run tries it again.
        failedDays.Add(day);
        Console.WriteLine($"{label} FAILED: {Safe(ex.Message)}");
        if (failedDays.Count >= 20)
        {
            Console.WriteLine("Stopping: 20 days failed. Run again later; finished days are skipped.");
            break;
        }
    }
}

Console.WriteLine($"finished: {totalInserted:N0} rows inserted, {failedDays.Count} day(s) failed");
foreach (var (name, count) in unknownMarkets.OrderByDescending(m => m.Value).Take(25))
    Console.WriteLine($"  market not in catalog: {name} ({count:N0} rows)");

async Task<List<Row>> FetchDay(DateOnly day)
{
    var rows = new List<Row>();
    var date = Uri.EscapeDataString(day.ToString("dd/MM/yyyy", CultureInfo.InvariantCulture));
    while (true)
    {
        var url = $"https://api.data.gov.in/resource/{Resource}?api-key={Uri.EscapeDataString(key)}&format=json&limit={PageSize}&offset={rows.Count}&filters%5BArrival_Date%5D={date}";
        using var page = await GetJson(url);
        var root = page.RootElement;
        if (root.GetProperty("status").GetString() != "ok") throw new InvalidOperationException("The feed answered with a non-ok status.");
        var total = int.Parse(root.GetProperty("total").ToString(), CultureInfo.InvariantCulture);
        var before = rows.Count;
        foreach (var r in root.GetProperty("records").EnumerateArray())
        {
            rows.Add(new Row(Text(r, "Commodity"), Text(r, "Variety"), Text(r, "Market"), Text(r, "Min_Price"), Text(r, "Max_Price"), Text(r, "Modal_Price"), Text(r, "Arrival_Date"), Text(r, "State"), Text(r, "District")));
        }

        if (rows.Count >= total) return rows;
        if (rows.Count == before) throw new InvalidOperationException($"The feed stopped at {rows.Count} of {total} rows.");
        await Task.Delay(300);
    }
}

async Task<JsonDocument> GetJson(string url)
{
    for (var attempt = 1; ; attempt++)
    {
        try
        {
            using var response = await http.GetAsync(url);
            response.EnsureSuccessStatusCode();
            return JsonDocument.Parse(await response.Content.ReadAsByteArrayAsync());
        }
        catch (Exception ex) when (attempt < 5 && ex is HttpRequestException or TaskCanceledException or JsonException)
        {
            await Task.Delay(TimeSpan.FromSeconds(5 * attempt));
        }
    }
}

async Task<Counts> Store(DateOnly day, List<Row> rows)
{
    int inserted = 0, existing = 0, unknown = 0, invalid = 0, duplicate = 0;
    var stored = new HashSet<(Guid, Guid?, Guid, Guid)>();
    await using (var command = db.CreateCommand(
        "select product_id, variant_id, unit_id, mandi_id from pricing.price_records where price_source_id = $1 and record_date = $2 and not is_voided and mandi_id is not null"))
    {
        command.Parameters.AddWithValue(sourceId);
        command.Parameters.AddWithValue(day);
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
            stored.Add((reader.GetGuid(0), reader.IsDBNull(1) ? null : reader.GetGuid(1), reader.GetGuid(2), reader.GetGuid(3)));
    }

    var seen = new HashSet<(Guid, Guid?, Guid, Guid)>();
    var pending = new List<(Guid Product, Guid? Variant, Guid Unit, Guid Mandi, decimal? Min, decimal? Max, decimal Modal)>();
    var unknownVariety = new List<(Row Row, Guid Product, Guid Unit, decimal Factor, Guid Mandi)>();

    void Add(Row row, Guid product, Guid? variant, Guid unit, decimal factor, Guid mandi, bool fallback)
    {
        var modal = Number(row.Modal);
        var min = Positive(Number(row.Min));
        var max = Positive(Number(row.Max));
        if (modal is not > 0 || decimal.Round(modal.Value, 2) != modal.Value || min > modal || max < modal) { invalid++; return; }
        var identity = (product, variant, unit, mandi);
        if (!seen.Add(identity)) { if (!fallback) duplicate++; return; }
        if (stored.Contains(identity)) { existing++; return; }
        decimal? Convert(decimal? price) => price is { } p ? decimal.Round(p * factor, 4) : null;
        pending.Add((product, variant, unit, mandi, Convert(min), Convert(max), Convert(modal)!.Value));
    }

    foreach (var row in rows)
    {
        // The feed is filtered by date; a row with any other date is not trusted into this day.
        if (!DateOnly.TryParseExact(row.Date, ["dd/MM/yyyy", "d/M/yyyy"], CultureInfo.InvariantCulture, DateTimeStyles.None, out var rowDate) || rowDate != day) { invalid++; continue; }
        var productCode = Mapped(Slug(row.Commodity), commodityMap);
        var mandiCode = MarketCodeFor(row);
        if (!products.TryGetValue(productCode, out var product)) { unknown++; continue; }
        if (!mandis.TryGetValue(mandiCode, out var mandi) && !TryOlderName(row, out mandi))
        {
            unknown++;
            unknownMarkets[row.Market] = unknownMarkets.GetValueOrDefault(row.Market) + 1;
            continue;
        }

        var variety = row.Variety.Trim();
        if (variety.Length == 0 || variety.ToLowerInvariant() is "faq" or "unclassified" or "other" or "-")
            Add(row, product.Id, null, product.Unit, product.Factor, mandi, false);
        else if (variants.TryGetValue((product.Id, Slug(variety)), out var variantId))
            Add(row, product.Id, variantId, product.Unit, product.Factor, mandi, false);
        else
            unknownVariety.Add((row, product.Id, product.Unit, product.Factor, mandi));
    }

    // As in the daily pull: a variety the catalog does not track becomes the product's general price, after real ones.
    foreach (var (row, product, unit, factor, mandi) in unknownVariety) Add(row, product, null, unit, factor, mandi, true);

    if (pending.Count > 0)
    {
        await using var conn = await db.OpenConnectionAsync();
        await using var copy = await conn.BeginBinaryImportAsync(
            "COPY pricing.price_records (id, product_id, variant_id, unit_id, location_kind, mandi_id, price_source_id, min_price, max_price, modal_price, record_date, is_voided, created_at_utc) FROM STDIN (FORMAT BINARY)");
        var now = DateTime.UtcNow;
        foreach (var p in pending)
        {
            await copy.StartRowAsync();
            await copy.WriteAsync(Guid.CreateVersion7(), NpgsqlDbType.Uuid);
            await copy.WriteAsync(p.Product, NpgsqlDbType.Uuid);
            if (p.Variant is { } v) await copy.WriteAsync(v, NpgsqlDbType.Uuid); else await copy.WriteNullAsync();
            await copy.WriteAsync(p.Unit, NpgsqlDbType.Uuid);
            await copy.WriteAsync("Mandi", NpgsqlDbType.Varchar);
            await copy.WriteAsync(p.Mandi, NpgsqlDbType.Uuid);
            await copy.WriteAsync(sourceId, NpgsqlDbType.Uuid);
            if (p.Min is { } min) await copy.WriteAsync(min, NpgsqlDbType.Numeric); else await copy.WriteNullAsync();
            if (p.Max is { } max) await copy.WriteAsync(max, NpgsqlDbType.Numeric); else await copy.WriteNullAsync();
            await copy.WriteAsync(p.Modal, NpgsqlDbType.Numeric);
            await copy.WriteAsync(day, NpgsqlDbType.Date);
            await copy.WriteAsync(false, NpgsqlDbType.Boolean);
            await copy.WriteAsync(now, NpgsqlDbType.TimestampTz);
        }

        await copy.CompleteAsync();
        inserted = pending.Count;
    }

    return new Counts(inserted, existing, unknown, invalid, duplicate);
}

// As in the API: a "State/slug" map entry applies to that state only.
string MarketCodeFor(Row row)
{
    var slug = Slug(row.Market);
    return marketMap.TryGetValue($"{Mapped(row.State.Trim(), stateMap)}/{slug}", out var inState) ? inState : Mapped(slug, marketMap);
}

bool TryOlderName(Row row, out Guid mandi)
{
    // The same state and district spellings as the API's market import are accepted.
    var state = Mapped(row.State.Trim(), stateMap);
    var district = Mapped($"{state}/{row.District.Trim()}", districtMap);
    if (district.Contains('/')) district = row.District.Trim();
    var key = (state.ToLowerInvariant(), district.ToLowerInvariant(), NameKey(row.Market));
    var found = sameName.TryGetValue(key, out var id) ? id : null;
    mandi = found ?? Guid.Empty;
    return found is not null;
}

async Task<object?> Scalar(string sql)
{
    await using var command = db.CreateCommand(sql);
    return await command.ExecuteScalarAsync();
}

async IAsyncEnumerable<NpgsqlDataReader> Query(string sql)
{
    await using var command = db.CreateCommand(sql);
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync()) yield return reader;
}

string Safe(string message) => message.Replace(key, "***", StringComparison.Ordinal);

static string Text(JsonElement row, string name) =>
    row.TryGetProperty(name, out var value) && value.ValueKind != JsonValueKind.Null ? value.ToString() : string.Empty;

static decimal? Number(string value) =>
    decimal.TryParse(value.Trim().Replace(",", string.Empty, StringComparison.Ordinal), NumberStyles.Number, CultureInfo.InvariantCulture, out var n) ? n : null;

static decimal? Positive(decimal? value) => value > 0 ? value : null;

static string Escape(string value) => JsonEncodedText.Encode(value).ToString();

static string Slug(string value) => Regex.Replace(value.Trim().ToLowerInvariant(), "[^a-z0-9]+", "-").Trim('-');

// Only the generic words are ignored; anything else, such as "(Grain)" or "(F&V)", keeps two market yards apart.
static string NameKey(string name) =>
    Regex.Replace(Regex.Replace(name.ToLowerInvariant(), @"\b(apmc|market|mandi|smy|pmy)\b", " "), "[^a-z0-9]+", "");

static string Mapped(string code, Dictionary<string, string> map) => map.TryGetValue(code, out var mapped) ? mapped : code;

static (Dictionary<string, string> Markets, Dictionary<string, string> Commodities, Dictionary<string, string> States, Dictionary<string, string> Districts) ReadCodeMaps(string path)
{
    using var settings = JsonDocument.Parse(File.ReadAllText(path), new JsonDocumentOptions { CommentHandling = JsonCommentHandling.Skip, AllowTrailingCommas = true });
    var feed = settings.RootElement.GetProperty("Agmarknet");

    Dictionary<string, string> Read(string name) =>
        feed.TryGetProperty(name, out var map)
            ? map.EnumerateObject().ToDictionary(p => p.Name, p => p.Value.GetString() ?? p.Name, StringComparer.OrdinalIgnoreCase)
            : new(StringComparer.OrdinalIgnoreCase);

    return (Read("MarketCodeMap"), Read("CommodityCodeMap"), Read("StateNameMap"), Read("DistrictNameMap"));
}

internal sealed record Row(string Commodity, string Variety, string Market, string Min, string Max, string Modal, string Date, string State, string District);

internal readonly record struct Counts(int Inserted, int Existing, int Unknown, int Invalid, int Duplicate);
