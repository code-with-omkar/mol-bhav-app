using System.Globalization;
using System.Text;

namespace MolBhav.Infrastructure.Reporting;

/// <summary>
/// RFC 4180 CSV: invariant numbers and ISO dates for spreadsheets and scripts; names stay in the requested language.
/// Written with a UTF-8 BOM so Excel shows Indic names correctly.
/// </summary>
internal static class PriceHistoryCsv
{
    private static readonly string[] Header =
    [
        "date", "product", "variant", "location_type", "location", "district", "state",
        "min_price", "max_price", "modal_price", "unit", "arrival_quantity", "source",
    ];

    public static byte[] Write(IReadOnlyList<PriceHistoryRow> rows)
    {
        using var buffer = new MemoryStream();
        using (var writer = new StreamWriter(buffer, new UTF8Encoding(encoderShouldEmitUTF8Identifier: true)) { NewLine = "\r\n" })
        {
            WriteLine(writer, Header);
            foreach (var r in rows)
            {
                WriteLine(writer,
                [
                    r.RecordDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                    r.ProductName,
                    r.VariantName,
                    r.LocationKind,
                    r.LocationName,
                    r.DistrictName,
                    r.StateName,
                    Number(r.MinPrice),
                    Number(r.MaxPrice),
                    Number(r.ModalPrice),
                    r.UnitSymbol,
                    Number(r.ArrivalQuantity),
                    r.SourceName,
                ]);
            }
        }

        return buffer.ToArray();
    }

    private static string? Number(decimal? value) => value?.ToString(CultureInfo.InvariantCulture);

    private static void WriteLine(StreamWriter writer, string?[] fields)
    {
        for (var i = 0; i < fields.Length; i++)
        {
            if (i > 0)
            {
                writer.Write(',');
            }

            writer.Write(Escape(fields[i]));
        }

        writer.WriteLine();
    }

    private static string Escape(string? value)
    {
        if (string.IsNullOrEmpty(value))
        {
            return string.Empty;
        }

        // Leading = + - @ would run as a formula in a spreadsheet; prefix with ' (OWASP CSV injection guidance).
        if (value[0] is '=' or '+' or '-' or '@')
        {
            value = "'" + value;
        }

        return value.IndexOfAny([',', '"', '\r', '\n']) >= 0 ? $"\"{value.Replace("\"", "\"\"", StringComparison.Ordinal)}\"" : value;
    }
}
