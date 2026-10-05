using System.Globalization;
using System.Text.RegularExpressions;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Domain.Pricing;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Maps one Agmarknet row (from the data.gov.in API or an uploaded CSV) onto an <see cref="IngestedPriceRecord"/>:
/// slugs commodity / variety / market to the catalog's code format, applies the admin-configured code overrides,
/// parses prices and the arrival date. Shared so an API pull and a file upload of the same day map identically.
/// </summary>
internal static partial class AgmarknetRowMapper
{
    /// <summary>Generic Agmarknet variety labels that mean "no specific variety".</summary>
    private static readonly HashSet<string> GenericVarieties = new(StringComparer.OrdinalIgnoreCase) { "faq", "unclassified", "other", "-" };

    private static readonly string[] DateFormats =
    [
        "dd/MM/yyyy", "d/M/yyyy", "dd-MM-yyyy", "d-M-yyyy", "yyyy-MM-dd",
        "dd MMM yyyy", "d MMM yyyy", "dd-MMM-yyyy", "d-MMM-yyyy", "dd MMM yy", "dd-MMM-yy",
    ];

    /// <summary>
    /// Null with a reason when a required field is missing or unparseable. <paramref name="fallbackDate"/> is used only
    /// when the row has no date at all (API rows filtered by date); a present-but-unreadable date is an error.
    /// </summary>
    public static IngestedPriceRecord? Map(
        string? commodity,
        string? variety,
        string? market,
        string? minPrice,
        string? maxPrice,
        string? modalPrice,
        string? arrivalQuantity,
        string? arrivalDate,
        DateOnly? fallbackDate,
        AgmarknetOptions options,
        out string? failureReason)
    {
        ArgumentNullException.ThrowIfNull(options);
        failureReason = null;

        var productCode = Remap(ToCode(commodity), options.CommodityCodeMap);
        if (productCode.Length == 0)
        {
            failureReason = "Commodity is missing.";
            return null;
        }

        var locationCode = Remap(ToCode(market), options.MarketCodeMap);
        if (locationCode.Length == 0)
        {
            failureReason = "Market is missing.";
            return null;
        }

        if (!TryParseDecimal(modalPrice, out var modal) || modal <= 0)
        {
            failureReason = $"Modal price '{modalPrice}' is not a positive number.";
            return null;
        }

        DateOnly recordDate;
        if (string.IsNullOrWhiteSpace(arrivalDate))
        {
            if (fallbackDate is not { } fallback)
            {
                failureReason = "Arrival date is missing.";
                return null;
            }

            recordDate = fallback;
        }
        else if (ParseDate(arrivalDate) is { } parsed)
        {
            recordDate = parsed;
        }
        else
        {
            failureReason = $"Arrival date '{arrivalDate}' is not a recognised date (use dd/MM/yyyy).";
            return null;
        }

        return new IngestedPriceRecord(
            ProductCode: productCode,
            VariantCode: ToVariantCode(variety),
            LocationKind: LocationKind.Mandi, // Agmarknet is always mandis.
            LocationCode: locationCode,
            MinPrice: ParsePositiveOrNull(minPrice),
            MaxPrice: ParsePositiveOrNull(maxPrice),
            ModalPrice: modal,
            ArrivalQuantity: ParsePositiveOrNull(arrivalQuantity),
            RecordDate: recordDate);
    }

    /// <summary>"Red Onion (Large)" → "red-onion-large" — the slug format admins use for product and mandi codes.</summary>
    public static string ToCode(string? value) =>
        string.IsNullOrWhiteSpace(value) ? string.Empty : SlugNonAlpha().Replace(value.Trim().ToLowerInvariant(), "-").Trim('-');

    public static DateOnly? ParseDate(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var trimmed = value.Trim();

        // Spreadsheet exports sometimes append a time ("03/10/2026 00:00:00").
        var space = trimmed.IndexOf(' ', StringComparison.Ordinal);
        if (space > 0 && trimmed.IndexOf(':', StringComparison.Ordinal) > space)
        {
            trimmed = trimmed[..space];
        }

        return DateOnly.TryParseExact(trimmed, DateFormats, CultureInfo.InvariantCulture, DateTimeStyles.None, out var date)
            ? date
            : null;
    }

    private static string Remap(string code, Dictionary<string, string> map) =>
        code.Length > 0 && map.TryGetValue(code, out var mapped) && !string.IsNullOrWhiteSpace(mapped) ? mapped.Trim() : code;

    private static string? ToVariantCode(string? value) =>
        string.IsNullOrWhiteSpace(value) || GenericVarieties.Contains(value.Trim()) ? null : ToCode(value);

    private static bool TryParseDecimal(string? value, out decimal result)
    {
        result = 0;

        // Exports may carry thousands separators ("1,250.00").
        return !string.IsNullOrWhiteSpace(value)
               && decimal.TryParse(value.Trim().Replace(",", string.Empty, StringComparison.Ordinal), NumberStyles.Number, CultureInfo.InvariantCulture, out result);
    }

    private static decimal? ParsePositiveOrNull(string? value) =>
        TryParseDecimal(value, out var parsed) && parsed > 0 ? parsed : null;

    [GeneratedRegex(@"[^a-z0-9]+")]
    private static partial Regex SlugNonAlpha();
}
