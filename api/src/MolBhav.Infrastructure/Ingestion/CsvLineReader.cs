using System.Text;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Minimal RFC 4180 reader: comma-separated, double-quoted fields may contain commas, quotes ("") and line breaks.
/// Yields each record with the 1-based line number it started on. No dependency needed for the one format we read.
/// </summary>
internal static class CsvLineReader
{
    public static async IAsyncEnumerable<(int LineNumber, IReadOnlyList<string> Fields, string RawText)> ReadAsync(
        TextReader reader,
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(reader);

        var lineNumber = 0;
        while (await reader.ReadLineAsync(cancellationToken) is { } line)
        {
            lineNumber++;
            var startLine = lineNumber;
            var raw = new StringBuilder(line);
            var fields = new List<string>();
            var field = new StringBuilder();
            var inQuotes = false;
            var text = line;
            var i = 0;

            while (true)
            {
                if (i >= text.Length)
                {
                    if (inQuotes && await reader.ReadLineAsync(cancellationToken) is { } next)
                    {
                        // A quoted field spans lines: keep the line break inside the field.
                        lineNumber++;
                        field.Append('\n');
                        raw.Append('\n').Append(next);
                        text = next;
                        i = 0;
                        continue;
                    }

                    break;
                }

                var c = text[i];
                if (inQuotes)
                {
                    if (c == '"')
                    {
                        if (i + 1 < text.Length && text[i + 1] == '"')
                        {
                            field.Append('"');
                            i += 2;
                            continue;
                        }

                        inQuotes = false;
                    }
                    else
                    {
                        field.Append(c);
                    }
                }
                else if (c == '"')
                {
                    inQuotes = true;
                }
                else if (c == ',')
                {
                    fields.Add(field.ToString());
                    field.Clear();
                }
                else
                {
                    field.Append(c);
                }

                i++;
            }

            fields.Add(field.ToString());
            yield return (startLine, fields, raw.ToString());
        }
    }
}
