using System.Globalization;
using System.Text;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Domain.Pricing;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// The MolBhav standard price template — one CSV layout for every category and every source without a dedicated parser
/// (construction rate sheets, supplier quotes, a future category's first feed). Codes are MolBhav catalog/market codes,
/// so no mapping tables are involved:
/// <code>
/// product_code,variant_code,location_kind,location_code,min_price,max_price,modal_price,arrival_qty,record_date
/// tmt-steel-bar,fe-500d,supplier,pune-steel-traders,,,62500,,2026-10-03
/// onion,red,mandi,pune-apmc,1800,2600,2200,1450,2026-10-03
/// </code>
/// Required: <c>product_code, location_kind (mandi|supplier), location_code, modal_price, record_date</c>.
/// Optional: <c>variant_code, min_price, max_price, arrival_qty</c>. Header names are matched loosely (case, spaces,
/// underscores ignored); prices may contain thousands separators; dates as yyyy-MM-dd, dd-MM-yyyy or dd/MM/yyyy.
/// Prices are in the product's default unit (the same rule as API ingestion).
/// </summary>
internal sealed class StandardPriceCsvParser : IIngestionFileParser
{
    public const string TemplateHeader =
        "product_code,variant_code,location_kind,location_code,min_price,max_price,modal_price,arrival_qty,record_date";

    /// <summary>Guard against a wrong (huge) file.</summary>
    private const int MaxDataRows = 250_000;

    private static readonly string[] DateFormats =
    [
        "yyyy-MM-dd", "dd-MM-yyyy", "dd/MM/yyyy", "d/M/yyyy", "d-M-yyyy", "dd-MMM-yyyy", "dd MMM yyyy", "yyyy/MM/dd",
    ];

    public async Task<IngestionFileParseResult> ParseAsync(string sourceCode, Stream content, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(content);

        var records = new List<IngestedPriceRecord>();
        var errors = new List<IngestionFileLineError>();
        Columns? columns = null;

        using var reader = new StreamReader(content, Encoding.UTF8, detectEncodingFromByteOrderMarks: true, leaveOpen: true);

        await foreach (var (lineNumber, fields, raw) in CsvLineReader.ReadAsync(reader, cancellationToken))
        {
            if (fields.All(string.IsNullOrWhiteSpace))
            {
                continue;
            }

            if (columns is null)
            {
                // The template has no title lines: the first non-blank line must be the header.
                columns = Columns.TryResolve(fields);
                if (columns is null)
                {
                    return IngestionFileParseResult.Failed(
                        $"This file is not in the MolBhav price template. The first line must be: {TemplateHeader}");
                }

                continue;
            }

            if (records.Count + errors.Count >= MaxDataRows)
            {
                return IngestionFileParseResult.Failed($"The file has more than {MaxDataRows:N0} rows. Split it by date.");
            }

            var record = MapRow(columns, fields, out var reason);
            if (record is null)
            {
                errors.Add(new IngestionFileLineError(lineNumber, Truncate(raw), reason));
            }
            else
            {
                records.Add(record);
            }
        }

        if (columns is null)
        {
            return IngestionFileParseResult.Failed("The file is empty.");
        }

        return records.Count == 0 && errors.Count == 0
            ? IngestionFileParseResult.Failed("The file has a header row but no data rows.")
            : IngestionFileParseResult.Success(records, errors);
    }

    /// <summary>True when the first non-blank line is a standard-template header. Reads from the current position.</summary>
    public static async Task<bool> LooksLikeTemplateAsync(Stream content, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(content);

        using var reader = new StreamReader(content, Encoding.UTF8, detectEncodingFromByteOrderMarks: true, leaveOpen: true);
        await foreach (var (_, fields, _) in CsvLineReader.ReadAsync(reader, cancellationToken))
        {
            if (fields.All(string.IsNullOrWhiteSpace))
            {
                continue;
            }

            return Columns.TryResolve(fields) is not null;
        }

        return false;
    }

    private static IngestedPriceRecord? MapRow(Columns columns, IReadOnlyList<string> fields, out string reason)
    {
        var productCode = Columns.Get(fields, columns.ProductCode);
        if (productCode is null)
        {
            reason = "product_code is empty.";
            return null;
        }

        var locationCode = Columns.Get(fields, columns.LocationCode);
        if (locationCode is null)
        {
            reason = "location_code is empty.";
            return null;
        }

        LocationKind locationKind;
        switch (Columns.Get(fields, columns.LocationKind)?.ToLowerInvariant())
        {
            case "mandi":
                locationKind = LocationKind.Mandi;
                break;
            case "supplier":
                locationKind = LocationKind.Supplier;
                break;
            case var other:
                reason = $"location_kind must be 'mandi' or 'supplier' (got '{other ?? string.Empty}').";
                return null;
        }

        if (!TryParseDecimal(Columns.Get(fields, columns.ModalPrice), out var modal) || modal <= 0)
        {
            reason = "modal_price must be a positive number.";
            return null;
        }

        if (!TryParseOptionalPositive(Columns.Get(fields, columns.MinPrice), out var min))
        {
            reason = "min_price must be a positive number or empty.";
            return null;
        }

        if (!TryParseOptionalPositive(Columns.Get(fields, columns.MaxPrice), out var max))
        {
            reason = "max_price must be a positive number or empty.";
            return null;
        }

        if (!TryParseOptionalPositive(Columns.Get(fields, columns.ArrivalQuantity), out var arrival))
        {
            reason = "arrival_qty must be a positive number or empty.";
            return null;
        }

        var dateText = Columns.Get(fields, columns.RecordDate);
        if (dateText is null
            || !DateOnly.TryParseExact(dateText, DateFormats, CultureInfo.InvariantCulture, DateTimeStyles.None, out var recordDate))
        {
            reason = $"record_date '{dateText ?? string.Empty}' is not a date (use yyyy-MM-dd).";
            return null;
        }

        reason = string.Empty;
        return new IngestedPriceRecord(
            productCode,
            Columns.Get(fields, columns.VariantCode),
            locationKind,
            locationCode,
            min,
            max,
            modal,
            arrival,
            recordDate);
    }

    private static bool TryParseDecimal(string? value, out decimal result)
    {
        result = 0;
        return !string.IsNullOrWhiteSpace(value)
            && decimal.TryParse(
                value.Replace(",", string.Empty, StringComparison.Ordinal),
                NumberStyles.Number,
                CultureInfo.InvariantCulture,
                out result);
    }

    /// <summary>Empty → true with null; otherwise must parse and be &gt; 0.</summary>
    private static bool TryParseOptionalPositive(string? value, out decimal? result)
    {
        result = null;
        if (string.IsNullOrWhiteSpace(value))
        {
            return true;
        }

        if (!TryParseDecimal(value, out var parsed) || parsed <= 0)
        {
            return false;
        }

        result = parsed;
        return true;
    }

    private static string Truncate(string raw) => raw.Length <= 500 ? raw : raw[..500];

    /// <summary>Column positions from the header; -1 when an optional column is absent.</summary>
    private sealed class Columns
    {
        public int ProductCode { get; private init; } = -1;

        public int VariantCode { get; private init; } = -1;

        public int LocationKind { get; private init; } = -1;

        public int LocationCode { get; private init; } = -1;

        public int MinPrice { get; private init; } = -1;

        public int MaxPrice { get; private init; } = -1;

        public int ModalPrice { get; private init; } = -1;

        public int ArrivalQuantity { get; private init; } = -1;

        public int RecordDate { get; private init; } = -1;

        /// <summary>The trimmed cell, or null when the column is absent or the cell is blank.</summary>
        public static string? Get(IReadOnlyList<string> fields, int index) =>
            index >= 0 && index < fields.Count && !string.IsNullOrWhiteSpace(fields[index]) ? fields[index].Trim() : null;

        public static Columns? TryResolve(IReadOnlyList<string> header)
        {
            var keys = header.Select(Normalize).ToArray();

            int Find(params string[] names) => Array.FindIndex(keys, k => names.Contains(k, StringComparer.Ordinal));

            var columns = new Columns
            {
                ProductCode = Find("productcode", "product"),
                VariantCode = Find("variantcode", "variant"),
                LocationKind = Find("locationkind", "locationtype"),
                LocationCode = Find("locationcode", "location"),
                MinPrice = Find("minprice"),
                MaxPrice = Find("maxprice"),
                ModalPrice = Find("modalprice", "price"),
                ArrivalQuantity = Find("arrivalqty", "arrivalquantity"),
                RecordDate = Find("recorddate", "pricedate", "date"),
            };

            return columns is { ProductCode: >= 0, LocationKind: >= 0, LocationCode: >= 0, ModalPrice: >= 0, RecordDate: >= 0 }
                ? columns
                : null;
        }

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
