using System.Text;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Ingestion;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Reads Agmarknet price CSVs in either layout admins can get when the API is down:
/// <list type="bullet">
/// <item>data.gov.in export — <c>state, district, market, commodity, variety, grade, arrival_date, min_price, max_price, modal_price</c></item>
/// <item>Agmarknet portal report — <c>Market Name, Commodity, Variety, Arrivals, Min Price (Rs./Quintal), …, Price Date</c></item>
/// </list>
/// Headers are matched loosely (case, spaces, punctuation and units ignored) and may sit below a few title lines.
/// Every data row goes through <see cref="AgmarknetRowMapper"/>, exactly like an API row. Registered keyed under
/// <c>agmarknet</c>; <see cref="IngestionFileParserDispatcher"/> routes to it. An Agmarknet source can still take the
/// MolBhav standard template — the header decides (see <see cref="IngestionFileParserDispatcher"/>).
/// </summary>
internal sealed class AgmarknetCsvParser(IOptions<AgmarknetOptions> options) : IIngestionFileParser
{
    /// <summary>Title lines a portal export may have above the header row.</summary>
    private const int MaxHeaderSearchLines = 15;

    /// <summary>Guard against a wrong (huge) file; ~16k rows is a full national day.</summary>
    private const int MaxDataRows = 250_000;

    public async Task<IngestionFileParseResult> ParseAsync(string sourceCode, Stream content, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(content);

        var opts = options.Value;
        var records = new List<IngestedPriceRecord>();
        var errors = new List<IngestionFileLineError>();
        Columns? columns = null;

        // detectEncodingFromByteOrderMarks handles the UTF-8 BOM Excel adds.
        using var reader = new StreamReader(content, Encoding.UTF8, detectEncodingFromByteOrderMarks: true, leaveOpen: true);

        await foreach (var (lineNumber, fields, raw) in CsvLineReader.ReadAsync(reader, cancellationToken))
        {
            if (fields.All(string.IsNullOrWhiteSpace))
            {
                continue;
            }

            if (columns is null)
            {
                columns = Columns.TryResolve(fields);
                if (columns is null && lineNumber >= MaxHeaderSearchLines)
                {
                    return IngestionFileParseResult.Failed(
                        "No header row found. The file needs columns for commodity, market, modal price and arrival/price date.");
                }

                continue;
            }

            if (records.Count + errors.Count >= MaxDataRows)
            {
                return IngestionFileParseResult.Failed($"The file has more than {MaxDataRows:N0} rows. Split it by date or state.");
            }

            var record = AgmarknetRowMapper.Map(
                commodity: Columns.Get(fields, columns.Commodity),
                variety: Columns.Get(fields, columns.Variety),
                market: Columns.Get(fields, columns.Market),
                minPrice: Columns.Get(fields, columns.MinPrice),
                maxPrice: Columns.Get(fields, columns.MaxPrice),
                modalPrice: Columns.Get(fields, columns.ModalPrice),
                arrivalQuantity: Columns.Get(fields, columns.ArrivalQuantity),
                arrivalDate: Columns.Get(fields, columns.Date),
                fallbackDate: null,
                opts,
                out var reason);

            if (record is null)
            {
                errors.Add(new IngestionFileLineError(lineNumber, Truncate(raw), reason ?? "Row could not be read."));
            }
            else
            {
                records.Add(record);
            }
        }

        if (columns is null)
        {
            return IngestionFileParseResult.Failed("The file is empty or has no header row.");
        }

        return records.Count == 0 && errors.Count == 0
            ? IngestionFileParseResult.Failed("The file has a header row but no data rows.")
            : IngestionFileParseResult.Success(records, errors);
    }

    private static string Truncate(string raw) => raw.Length <= 500 ? raw : raw[..500];

    /// <summary>Column positions resolved from the header row; -1 when an optional column is absent.</summary>
    private sealed class Columns
    {
        public int Commodity { get; private init; } = -1;

        public int Variety { get; private init; } = -1;

        public int Market { get; private init; } = -1;

        public int MinPrice { get; private init; } = -1;

        public int MaxPrice { get; private init; } = -1;

        public int ModalPrice { get; private init; } = -1;

        public int ArrivalQuantity { get; private init; } = -1;

        public int Date { get; private init; } = -1;

        public static string? Get(IReadOnlyList<string> fields, int index) =>
            index >= 0 && index < fields.Count ? fields[index] : null;

        /// <summary>Null unless this row is a header with all required columns (commodity, market, modal price, date).</summary>
        public static Columns? TryResolve(IReadOnlyList<string> header)
        {
            var keys = header.Select(Normalize).ToArray();

            int Find(Func<string, bool> match) => Array.FindIndex(keys, k => k.Length > 0 && match(k));

            var columns = new Columns
            {
                Commodity = Find(k => k == "commodity" || k == "commodityname"),
                Variety = Find(k => k == "variety"),
                Market = Find(k => k == "market" || k == "marketname" || k == "mandi" || k == "apmc"),
                MinPrice = Find(k => k.StartsWith("minprice", StringComparison.Ordinal) || k.StartsWith("minimumprice", StringComparison.Ordinal)),
                MaxPrice = Find(k => k.StartsWith("maxprice", StringComparison.Ordinal) || k.StartsWith("maximumprice", StringComparison.Ordinal)),
                ModalPrice = Find(k => k.StartsWith("modalprice", StringComparison.Ordinal)),
                ArrivalQuantity = Find(k => k.StartsWith("arrival", StringComparison.Ordinal) && !k.StartsWith("arrivaldate", StringComparison.Ordinal)),
                Date = Find(k => k is "arrivaldate" or "pricedate" or "reporteddate" or "date"),
            };

            return columns is { Commodity: >= 0, Market: >= 0, ModalPrice: >= 0, Date: >= 0 } ? columns : null;
        }

        /// <summary>"Min Price (Rs./Quintal)" → "minpricersquintal"; "arrival_date" → "arrivaldate".</summary>
        private static string Normalize(string header)
        {
            var builder = new StringBuilder(header.Length);
            foreach (var c in header.Trim().ToLowerInvariant())
            {
                if (c is >= 'a' and <= 'z' or >= '0' and <= '9')
                {
                    builder.Append(c);
                }
            }

            return builder.ToString();
        }
    }
}
