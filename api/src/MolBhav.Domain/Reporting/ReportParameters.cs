namespace MolBhav.Domain.Reporting;

/// <summary>Keys of <see cref="Report.ParametersJson"/> and the report type/format pairs a renderer exists for.</summary>
public static class ReportParameters
{
    /// <summary>Inclusive start date, <c>yyyy-MM-dd</c>.</summary>
    public const string FromDate = "fromDate";

    /// <summary>Inclusive end date, <c>yyyy-MM-dd</c>.</summary>
    public const string ToDate = "toDate";

    /// <summary>ISO-639-1 code the report's names and labels are rendered in.</summary>
    public const string Language = "language";

    public const string ProductId = "productId";

    public const string MandiId = "mandiId";

    public const string DateFormat = "yyyy-MM-dd";

    public const int MaxRangeDays = 366;

    public static bool IsSupported(ReportType type, ReportFormat format) =>
        (type, format) is (ReportType.WeeklySummary, ReportFormat.Pdf) or (ReportType.PriceHistory, ReportFormat.Csv);

    /// <summary>Report types that need a paid plan.</summary>
    public static bool RequiresPro(ReportType type) => type == ReportType.PriceHistory;
}
