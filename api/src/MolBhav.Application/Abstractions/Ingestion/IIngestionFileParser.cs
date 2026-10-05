namespace MolBhav.Application.Abstractions.Ingestion;

/// <summary>
/// Turns an uploaded file (e.g. an Agmarknet CSV export) into the same normalized rows an adapter returns, so uploads
/// go through the exact mapping, de-duplication and error reporting of an API run. One implementation per file format;
/// it picks the layout from the header row.
/// </summary>
public interface IIngestionFileParser
{
    Task<IngestionFileParseResult> ParseAsync(string sourceCode, Stream content, CancellationToken cancellationToken = default);
}

/// <summary>A line that could not become a row: 1-based line number, the raw text, and why.</summary>
public sealed record IngestionFileLineError(int LineNumber, string RawLine, string Message);

public sealed record IngestionFileParseResult
{
    private IngestionFileParseResult(
        bool isSuccess, string? failureReason, IReadOnlyList<IngestedPriceRecord> records, IReadOnlyList<IngestionFileLineError> lineErrors)
    {
        IsSuccess = isSuccess;
        FailureReason = failureReason;
        Records = records;
        LineErrors = lineErrors;
    }

    /// <summary>False when the file as a whole is unusable (empty, unknown layout, missing required columns).</summary>
    public bool IsSuccess { get; }

    public string? FailureReason { get; }

    public IReadOnlyList<IngestedPriceRecord> Records { get; }

    public IReadOnlyList<IngestionFileLineError> LineErrors { get; }

    public static IngestionFileParseResult Success(IReadOnlyList<IngestedPriceRecord> records, IReadOnlyList<IngestionFileLineError> lineErrors) =>
        new(true, null, records, lineErrors);

    public static IngestionFileParseResult Failed(string reason) => new(false, reason, [], []);
}
